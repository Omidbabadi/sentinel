import 'package:sentinel/core/utils/typedefs.dart';

abstract class UsecaseWithParams<T, Params> {
  const UsecaseWithParams();

  ResultFuture<T> call(Params params);
}

abstract class UsecaseWithOutParams<T> {
  const UsecaseWithOutParams();

  ResultFuture<T> call();
}
