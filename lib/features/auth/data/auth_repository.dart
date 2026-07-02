import '../domain/login_request.dart';
import '../domain/login_response.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _authApi;

  AuthRepository(this._authApi);

  Future<LoginResponse> login(LoginRequest request) async {
    return await _authApi.login(request);
  }
}
