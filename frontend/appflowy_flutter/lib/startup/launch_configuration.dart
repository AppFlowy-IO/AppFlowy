class LaunchConfiguration {
  const LaunchConfiguration({
    this.isAnon = false,
    required this.version,
    required this.rustEnvs,
  });

  // APP will automatically register after launching.
  final bool isAnon;
  final String version;
  //
  final Map<String, String> rustEnvs;
}
