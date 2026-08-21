import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/local_cache_repository.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/customer_api.dart';
import '../data/user_profile_api.dart';
import '../domain/customer_profile.dart';
import '../domain/user_profile.dart';

final customerApiProvider = Provider<CustomerApi>((ref) {
  return CustomerApi();
});

final userProfileApiProvider = Provider<UserProfileApi>((ref) {
  return UserProfileApi();
});

final customerProfileProvider = FutureProvider.autoDispose<CustomerProfileData>(
  (ref) async {
    final onlineStatus = ref.watch(isOnlineProvider);
    final connectivityService = ref.read(connectivityServiceProvider);
    final customerApi = ref.read(customerApiProvider);
    final cache = ref.read(localCacheRepositoryProvider);
    final customerId = (await SecureStorageService.getCustomerId())?.trim();
    if (customerId == null || customerId.isEmpty) {
      throw StateError('Customer ID introuvable.');
    }

    final cacheKey = 'profile:customer:$customerId';
    final user = await _sessionUserProfile();

    if (!await _isOnline(connectivityService, onlineStatus)) {
      final cachedProfile = await _cachedProfile(cache, cacheKey);
      if (cachedProfile != null) return cachedProfile;
      throw StateError('Profil local indisponible hors ligne.');
    }

    try {
      final profile = await customerApi.getCustomerProfile(
        customerId: customerId,
      );
      final data = CustomerProfileData(user: user, customer: profile);
      await cache.saveJson(cacheKey, data.toJson());
      return data;
    } catch (_) {
      final cachedProfile = await _cachedProfile(cache, cacheKey);
      if (cachedProfile != null) return cachedProfile;
      rethrow;
    }
  },
);

class CustomerProfileData {
  const CustomerProfileData({required this.user, required this.customer});

  final UserProfile user;
  final CustomerProfile customer;

  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'customer': customer.toJson()};
  }
}

Future<bool> _isOnline(
  ConnectivityService connectivityService,
  AsyncValue<bool> onlineStatus,
) async {
  if (onlineStatus is AsyncData<bool>) return onlineStatus.value;
  return connectivityService.hasConnection();
}

Future<UserProfile> _sessionUserProfile() async {
  final session = await SecureStorageService.getSession();
  final username = await SecureStorageService.getUsername();
  final fallbackData = <String, dynamic>{...?session};
  if (username != null) {
    fallbackData['email'] = username;
  }
  return UserProfile.fromJson(fallbackData);
}

Future<CustomerProfileData?> _cachedProfile(
  LocalCacheRepository cache,
  String cacheKey,
) async {
  final cachedValue = await cache.readJson(cacheKey);
  if (cachedValue is! Map) return null;

  final user = cachedValue['user'];
  final customer = cachedValue['customer'];
  if (user is! Map || customer is! Map) return null;

  return CustomerProfileData(
    user: UserProfile.fromJson(Map<String, dynamic>.from(user)),
    customer: CustomerProfile.fromJson(Map<String, dynamic>.from(customer)),
  );
}
