class LoginResponse {
  final Map<String, dynamic> data;

  LoginResponse({required this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(data: json);
  }
}
