import 'package:dartssh2/dartssh2.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';

import '../repositories/ssh_repository.dart';

class Connect extends UsecaseWithParams<SSHClient, ConnectParams> {
  const Connect(this._repository);

  final SshRepository _repository;

  @override
  ResultFuture<SSHClient> call(ConnectParams params) =>
      _repository.connect(host: params.host);
}

class ConnectParams {
  final Host host;

  const ConnectParams({required this.host});
}
