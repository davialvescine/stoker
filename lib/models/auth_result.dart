class AuthResult {
  final bool isSuccess;
  final String? message;

  AuthResult._(this.isSuccess, this.message);

  factory AuthResult.success({String? message}) => AuthResult._(true, message);
  factory AuthResult.error(String message) => AuthResult._(false, message);
}
