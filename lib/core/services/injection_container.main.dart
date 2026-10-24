part of 'injection_container.dart';

final sl = GetIt.instance;
final appDatabase = AppDatabase.internal();
final secureStorage = FlutterSecureStorage();
final credentialStore = CredentialStore(secureStorage);
final connectivity = Connectivity();

Future<void> init() async {
  await _cacheInit();
  await _networkInit();
  await _init();
  await _sshInit();
}

Future<void> _init() async {
  sl
    ..registerLazySingleton(() => GetHosts(sl()))
    ..registerLazySingleton(() => AddHost(sl()))
    ..registerLazySingleton(() => UpdateHost(sl()))
    ..registerLazySingleton(() => DeleteHost(sl()))
    ..registerLazySingleton(() => PingHost(sl()))
    ..registerLazySingleton(() => PingAllHost(sl()))
    ..registerLazySingleton<HostRepository>(() => HostRepositoryImpl(sl()))
    ..registerLazySingleton<HostLocalDatasrc>(
      () => HostLocalDatasrcImpl(
        database: sl<AppDatabase>(),
        credentialStore: sl<CredentialStore>(),
        networkInfo: sl<NetworkInfo>(),
      ),
    )
    ..registerLazySingleton(() => GetGroups(sl()))
    ..registerLazySingleton(() => AddGroup(sl()))
    ..registerLazySingleton(() => UpdateGroup(sl()))
    ..registerLazySingleton(() => DeleteGroup(sl()))
    ..registerLazySingleton(() => AssignHostsToGroup(sl()))
    ..registerLazySingleton<GroupRepository>(() => GroupRepositoryImpl(sl()))
    ..registerLazySingleton<GroupLocalDatasrc>(
      () => GroupLocalDatasrcImpl(database: sl<AppDatabase>()),
    )
    ..registerLazySingleton(() => appDatabase)
    ..registerLazySingleton(() => credentialStore);
}

Future<void> _sshInit() async {
  final PromptHandler hostKeyPromptHandler = PromptsHandlerImpl();
  sl
    ..registerLazySingleton(() => Connect(sl()))
    ..registerLazySingleton<SshRepository>(() => SshRepositoryImpl(sl()))
    ..registerLazySingleton<SshDatasrc>(
      () => SshDatasrcImpl(
        credentialStore,
        sl<PromptHandler>(),
        sl<HostLocalDatasrc>(),
        sl<NetworkInfo>(),
      ),
    )
    ..registerLazySingleton<PromptHandler>(() => hostKeyPromptHandler);
}

Future<void> _cacheInit() async {
  final prefs = await SharedPreferences.getInstance();

  sl
    ..registerLazySingleton(() => CacheHelper(sl()))
    ..registerLazySingleton(() => prefs);
}

Future<void> _networkInit() async {
  sl
    ..registerLazySingleton<Connectivity>(() => connectivity)
    ..registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  await sl<NetworkInfo>().init();
}
