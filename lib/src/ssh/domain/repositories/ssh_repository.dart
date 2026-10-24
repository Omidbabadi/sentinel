import 'package:dartssh2/dartssh2.dart';
import 'package:sentinel/core/utils/typedefs.dart';

import '../../../../core/common/entities/host.dart';

abstract class SshRepository {
  ResultFuture<SSHClient> connect({required Host host});
}
