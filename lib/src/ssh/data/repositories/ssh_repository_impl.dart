import 'package:dartssh2/dartssh2.dart';
import 'package:dartz/dartz.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/errors/exceptions.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/data/model/host_model.dart';
import 'package:sentinel/src/ssh/domain/repositories/ssh_repository.dart';

import '../../../../core/errors/failures.dart';
import '../datasrc/ssh_datasrc.dart';

class SshRepositoryImpl implements SshRepository {
  const SshRepositoryImpl(this._dataSource);
  final SshDatasrc _dataSource;

  @override
  ResultFuture<SSHClient> connect({required Host host}) async {
    try {
      final result = await _dataSource.connect(host: host as HostModel);
      return Right(result);
    } on SshException catch (e) {
      return Left(SshFailure.fromException(e));
    }
  }
}
