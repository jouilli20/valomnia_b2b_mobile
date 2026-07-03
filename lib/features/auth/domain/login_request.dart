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
      'username': username,
      'password': password,
      'organisation': organisation,
    };
  }
}
