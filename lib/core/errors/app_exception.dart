sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class AppAuthException extends AppException {
  const AppAuthException(super.message);
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class PermissionException extends AppException {
  const PermissionException(super.message);
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}
