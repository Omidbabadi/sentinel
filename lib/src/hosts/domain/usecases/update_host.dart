import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/domain/repositories/host_repository.dart';

class UpdateHost extends UsecaseWithParams<void, UpdateHostParams> {
  const UpdateHost(this._repository);
  final HostRepository _repository;
  @override
  ResultFuture<void> call(UpdateHostParams params) => _repository.update(
    host: params.host,
    secret: params.secret,
    passphrase: params.passphrase,
  );
}

class UpdateHostParams {
  const UpdateHostParams({
    required this.host,
    this.secret,
    this.passphrase,
  });
  final Host host;
  final String? secret;
  final String? passphrase;
}
