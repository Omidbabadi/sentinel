import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/domain/repositories/host_repository.dart';

class AddHost extends UsecaseWithParams<int, AddHostParams> {
  const AddHost(this._repository);
  final HostRepository _repository;
  @override
  ResultFuture<int> call(AddHostParams params) => _repository.addHost(
    host: params.host,
    secret: params.secret,
    passphrase: params.passphrase,
  );
}

class AddHostParams {
  const AddHostParams({
    required this.host,
    required this.passphrase,
    required this.secret,
  });
  final Host host;
  final String secret;
  final String? passphrase;
}
