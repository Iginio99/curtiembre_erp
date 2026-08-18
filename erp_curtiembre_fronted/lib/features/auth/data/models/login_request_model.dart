class LoginRequestModel {
  const LoginRequestModel({
    required this.userName,
    required this.password,
  });

  final String userName;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'password': password,
    };
  }
}
