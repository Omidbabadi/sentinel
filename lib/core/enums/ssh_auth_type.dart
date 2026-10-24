enum SshAuthType {
  password,
  privateKey;

  String get value => name;

  static SshAuthType fromValue(String value) {
    return SshAuthType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SshAuthType.password,
    );
  }
}
