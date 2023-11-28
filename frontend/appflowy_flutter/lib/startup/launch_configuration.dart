class LaunchConfiguration {
  const LaunchConfiguration({
    this.isAnon = false,
    required this.rustEnvs,
  });

  // APP will automatically register after launching.
  final bool isAnon;
  //
  final Map<String, String> rustEnvs;
}
