class CacheException implements Exception {
  const CacheException({required this.message});
  final String message;
}

class SshException implements Exception {
  const SshException({required this.message});
  final String message;
}
