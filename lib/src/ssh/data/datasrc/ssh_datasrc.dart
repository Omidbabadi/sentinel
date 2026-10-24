import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:sentinel/core/common/application/cache_helper.dart';
import 'package:sentinel/core/security/credential_store.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/src/hosts/data/model/host_model.dart';
import 'package:sentinel/src/hosts/data/model/linux_os_model.dart';

import '../../../../core/common/internet_conectivity.dart';
import '../../../../core/enums/ssh_auth_type.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/handler/host_key_prompts_handler.dart';
import '../../../hosts/data/datasrc/host_local_datasrc.dart';

abstract class SshDatasrc {
  Future<SSHClient> connect({required HostModel host});
}

class SshDatasrcImpl implements SshDatasrc {
  const SshDatasrcImpl(
    this._credentialStore,
    this._hostKeyPromptHandler,
    this._hostLocalDatasrc,
    this._networkInfo,
  );

  final CredentialStore _credentialStore;
  final PromptHandler _hostKeyPromptHandler;
  final HostLocalDatasrc _hostLocalDatasrc;
  final NetworkInfo _networkInfo;

  @override
  Future<SSHClient> connect({required HostModel host}) async {
    final hostId = host.id;

    if (hostId == null) {
      throw const SshException(
        message: 'Cannot connect to a Host without a database ID.',
      );
    }

    final hasInternet = await _networkInfo.checkConnectivity();
    if (!hasInternet) {
      throw const SshException(
        message:
            'No internet connection. Connect to a network and try again.',
      );
    }

    final secret = await _credentialStore.readSecret(hostId);

    if (secret == null || secret.isEmpty) {
      throw const SshException(
        message: 'No SSH credentials found for this Host.',
      );
    }

    final cacheHelper = sl<CacheHelper>();
    final timeout = Duration(seconds: cacheHelper.getSshConnectionTimeout());
    final keepAliveSeconds = cacheHelper.getSshKeepAlive();

    final socket = await SSHSocket.connect(
      host.ip,
      host.port,
    ).timeout(timeout);

    SSHClient? client;

    try {
      final identities = <SSHKeyPair>[];

      if (host.authType == SshAuthType.privateKey) {
        final passphrase = await _credentialStore.readPassphrase(hostId);
        final pemContent = await _resolvePrivateKeyPem(secret);

        identities.addAll(
          SSHKeyPair.fromPem(
            pemContent,
            passphrase == null || passphrase.isEmpty ? null : passphrase,
          ),
        );
      }

      client = SSHClient(
        socket,
        username: host.username,
        onPasswordRequest: host.authType == SshAuthType.password
            ? () => secret
            : null,
        onUserInfoRequest: host.authType == SshAuthType.password
            ? (request) => List.filled(request.prompts.length, secret)
            : null,
        identities: host.authType == SshAuthType.privateKey ? identities : null,
        onVerifyHostKey: (keyType, fingerprint) async {
          return _verifyHostKey(
            fingerprint: fingerprint,
            host: host,
            keyType: keyType,
          );
        },
        handshakeTimeout: timeout,
        authTimeout: timeout,
        keepAliveInterval: keepAliveSeconds > 0
            ? Duration(seconds: keepAliveSeconds)
            : null,
      );

      await client.authenticated.timeout(timeout);

      await _detectAndPersistOs(client, host);

      return client;
    } on SshException {
      rethrow;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      if (client != null) {
        client.close();
      } else {
        socket.close();
      }
      if (e is SSHAuthFailError) {
        throw const SshException(
          message:
              'Authentication failed. Please verify your credentials '
              'and authentication method.',
        );
      }
      if (e is SSHHostkeyError) {
        throw const SshException(
          message: 'Host key verification failed or was rejected.',
        );
      }
      throw SshException(
        message: 'Error occurred during SSH connection: ${e.toString()}',
      );
    }
  }

  Future<void> _detectAndPersistOs(SSHClient client, HostModel host) async {
    try {
      final result = await client.run('cat /etc/os-release');
      final osReleaseString = utf8.decode(result);
      final detectedOs = LinuxOsModel.fromOsRelease(osReleaseString);

      final updatedHost = host.copyWith(
        os: detectedOs,
        updatedAt: DateTime.now(),
      );

      await _hostLocalDatasrc.update(host: updatedHost);
    } catch (e) {
      debugPrint('Could not detect or persist OS info: $e');
    }
  }

  Future<bool> _verifyHostKey({
    required HostModel host,
    required String keyType,
    required Uint8List fingerprint,
  }) async {
    debugPrint('verifying');
    final hostId = host.id;
    if (hostId == null) return false;

    final hexFingerprint = fingerprint
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':');
    final legacyFingerprint = utf8.decode(fingerprint, allowMalformed: true);
    final savedFingerprint = await _credentialStore.readHostFingerprint(hostId);
    if (savedFingerprint == hexFingerprint ||
        savedFingerprint == legacyFingerprint) {
      return true;
    }

    final isFirstConnection = savedFingerprint == null;
    final strictChecking = sl<CacheHelper>().getStrictHostKeyChecking();
    if (isFirstConnection && !strictChecking) {
      await _credentialStore.saveHostFingerprint(
        hostId: hostId,
        fingerprint: hexFingerprint,
      );
      return true;
    }

    final accepted = await _hostKeyPromptHandler.verifyHostKeyPromptsHandler(
      host: host,
      keyType: keyType,
      fingerprint: fingerprint,
      presentedFingerprint: hexFingerprint,
      isFirstConnection: isFirstConnection,
    );

    if (accepted) {
      await _credentialStore.saveHostFingerprint(
        hostId: hostId,
        fingerprint: hexFingerprint,
      );
    }

    return accepted;
  }

  Future<String> _resolvePrivateKeyPem(String secretOrPath) async {
    final trimmed = secretOrPath.trim();
    if (trimmed.startsWith('-----BEGIN')) {
      return trimmed;
    }

    var resolvedPath = trimmed;
    if (resolvedPath.startsWith('file://')) {
      resolvedPath = Uri.parse(resolvedPath).toFilePath();
    } else if (resolvedPath == '~' || resolvedPath.startsWith('~/')) {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        resolvedPath = resolvedPath == '~'
            ? home
            : '$home${resolvedPath.substring(1)}';
      }
    }

    final file = File(resolvedPath);
    if (!await file.exists()) {
      throw SshException(
        message: 'Private key file not found at path: $resolvedPath',
      );
    }

    try {
      final content = (await file.readAsString()).trim();
      if (content.isEmpty) {
        throw SshException(
          message: 'Private key file is empty: $resolvedPath',
        );
      }
      return content;
    } on SshException {
      rethrow;
    } catch (e) {
      throw SshException(
        message: 'Unable to read private key file ($resolvedPath): $e',
      );
    }
  }
}
