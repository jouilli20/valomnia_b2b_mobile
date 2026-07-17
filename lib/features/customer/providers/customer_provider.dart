import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../data/customer_api.dart';
import '../domain/customer_profile.dart';
import '../domain/user_profile.dart';

final customerApiProvider = Provider<CustomerApi>((ref) {
  return CustomerApi();
});

final customerProfileProvider = FutureProvider.autoDispose<CustomerProfileData>(
  (ref) async {
    final customerId = (await SecureStorageService.getCustomerId())?.trim();
    if (customerId == null || customerId.isEmpty) {
      throw StateError('Customer ID introuvable.');
    }

    final session = await SecureStorageService.getSession();
    final username = await SecureStorageService.getUsername();
    final fallbackData = <String, dynamic>{...?session};
    if (username != null) {
      fallbackData['email'] = username;
    }
    final user = UserProfile.fromJson(fallbackData);

    final profile = await ref
        .read(customerApiProvider)
        .getCustomerProfile(customerId: customerId);

    return CustomerProfileData(user: user, customer: profile);
  },
);

class CustomerProfileData {
  const CustomerProfileData({required this.user, required this.customer});

  final UserProfile user;
  final CustomerProfile customer;
}
