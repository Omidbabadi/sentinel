import 'package:sentinel/core/errors/exceptions.dart';

sealed class Failure {
  const Failure({required this.message, required this.statusCode});
  final String message;
  final int statusCode;
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message}) : super(statusCode: 3);
  CacheFailure.fromException(CacheException e) : this(message: e.message);
}

class SshFailure extends Failure {
  const SshFailure({required super.message}) : super(statusCode: 3);
  SshFailure.fromException(SshException e) : this(message: e.message);
}
