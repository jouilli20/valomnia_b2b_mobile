import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/secure_storage_service.dart';

import '../domain/login_request.dart';
import '../domain/login_response.dart';
import 'auth_repository_provider.dart';

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<LoginResponse?>>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AsyncValue<LoginResponse?>> {
  @override
  AsyncValue<LoginResponse?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> login({
    required String organisation,
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final connectivityService = ref.read(connectivityServiceProvider);
      final repository = ref.read(authRepositoryProvider);
      final isOnline = await connectivityService.hasConnection();
      if (!isOnline) {
        throw StateError('Connexion Internet requise pour vous authentifier.');
      }

      final request = LoginRequest(
        organisation: organisation,
        username: username,
        password: password,
      );

      final response = await repository.login(request);
      await SecureStorageService.saveSession(response.data);

      await SecureStorageService.saveUsername(username);

      await SecureStorageService.saveOrganisation(organisation);

      state = AsyncValue.data(response);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
