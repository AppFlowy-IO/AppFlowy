class AiScrollService {
  AiScrollService({
    required this.onCreateAiWriter,
    required this.onDisposeAiWriter,
    required this.canScrollEditor,
  });

  final void Function() onCreateAiWriter;
  final void Function() onDisposeAiWriter;
  final bool Function() canScrollEditor;
}
