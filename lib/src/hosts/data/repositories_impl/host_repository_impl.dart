import 'package:dartz/dartz.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/errors/exceptions.dart';
import 'package:sentinel/core/errors/failures.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/data/datasrc/host_local_datasrc.dart';
import 'package:sentinel/src/hosts/data/model/host_model.dart';
import 'package:sentinel/src/hosts/domain/repositories/host_repository.dart';

class HostRepositoryImpl implements HostRepository {
  const HostRepositoryImpl(this._localDatasrc);
  final HostLocalDatasrc _localDatasrc;

  @override
  ResultFuture<List<Host>> getHosts() async {
    try {
      final hosts = await _localDatasrc.getHosts();
      return Right(hosts);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  HostModel _toModel(Host host) =>
      host is HostModel ? host : HostModel.fromEntity(host);

  @override
  ResultFuture<int> addHost({
    required Host host,
    required String secret,
    String? passphrase,
  }) async {
    try {
      final id = await _localDatasrc.addHost(
        host: _toModel(host),
        secret: secret,
        passphrase: passphrase,
      );
      return Right(id);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<void> update({
    required Host host,
    String? secret,
    String? passphrase,
  }) async {
    try {
      await _localDatasrc.update(
        host: _toModel(host),
        secret: secret,
        passphrase: passphrase,
      );
      return Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<void> delete(int hostId) async {
    try {
      await _localDatasrc.delete(hostId);
      return Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<List<Host>> pingAllHosts({
    required List<Host> host,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final models = host.map(_toModel).toList();
      final results = await _localDatasrc.pingAllHosts(
        hosts: models,
        timeout: timeout,
      );
      return Right(results);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<Host> pingHost({
    required Host host,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final result = await _localDatasrc.pingHost(
        host: _toModel(host),
        timeout: timeout,
      );
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }
}
