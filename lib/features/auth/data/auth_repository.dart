import '../domain/login_request.dart';
import '../domain/login_response.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _authApi;

  AuthRepository(this._authApi);

  Future<LoginResponse> login(LoginRequest request) async {
    return await _authApi.login(request);
  }

  Future<void> forgotPassword({
    required String email,
    required String organization,
  }) async {
    return await _authApi.forgotPassword(
      email: email,
      organization: organization,
    );
  }
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    return _authApi.resetPassword(
      token: token,
      password: password,
    );
  }
}
