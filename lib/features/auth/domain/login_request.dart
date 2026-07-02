class LoginRequest {
  final String organisation;
  final String username;
  final String password;

  LoginRequest({
    required this.organisation,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'organisation': organisation,
      'username': username,
      'password': password,
    };
  }
}
