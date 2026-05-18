class Failure implements Exception {
  Failure(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == null;

  @override
  String toString() => 'Failure($code, $statusCode): $message';
}
