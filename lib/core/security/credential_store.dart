import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStore {
  const CredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  String _secretKey(int hostId) => 'host_${hostId}_secret';
  String _passphraseKey(int hostId) => 'host_${hostId}_passphrase';
  String _hostFingerprintKey(int hostId) => 'host_${hostId}_ssh_fingerprint';

  Future<void> save({
    required int hostId,
    required String secret,
    String? passphrase,
  }) async {
    await _storage.write(key: _secretKey(hostId), value: secret);

    if (passphrase != null && passphrase.isNotEmpty) {
      await _storage.write(key: _passphraseKey(hostId), value: passphrase);
    } else {
      await _storage.delete(key: _passphraseKey(hostId));
    }
  }

  Future<String?> readSecret(int hostId) {
    return _storage.read(key: _secretKey(hostId));
  }

  Future<String?> readPassphrase(int hostId) {
    return _storage.read(key: _passphraseKey(hostId));
  }

  Future<String?> readHostFingerprint(int hostId) {
    return _storage.read(key: _hostFingerprintKey(hostId));
  }

  Future<void> saveHostFingerprint({
    required int hostId,
    required String fingerprint,
  }) {
    return _storage.write(key: _hostFingerprintKey(hostId), value: fingerprint);
  }

  Future<void> delete(int hostId) async {
    await _storage.delete(key: _secretKey(hostId));
    await _storage.delete(key: _passphraseKey(hostId));
    await _storage.delete(key: _hostFingerprintKey(hostId));
  }

  Future<int> clearAllHostFingerprints() async {
    final all = await _storage.readAll();
    int cleared = 0;
    for (final key in all.keys) {
      if (key.endsWith('_ssh_fingerprint')) {
        await _storage.delete(key: key);
        cleared++;
      }
    }
    return cleared;
  }
}
