import 'dart:io';

import 'package:appflowy/workspace/presentation/settings/widgets/ai/settings_ai_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class SettingsAIPage extends StatefulWidget {
  const SettingsAIPage({super.key});

  @override
  State<SettingsAIPage> createState() => _SettingsAIPageState();
}

class _SettingsAIPageState extends State<SettingsAIPage> {
  final localServerPathController = TextEditingController();
  final localLLMPathController = TextEditingController();

  @override
  void dispose() {
    localLLMPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsAIBloc()
        ..add(
          const SettingsAIEvent.initial(),
        ),
      child: BlocBuilder<SettingsAIBloc, SettingsAIState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Settings'),
                // download the exec
                TextField(
                  onSubmitted: (value) {
                    downloadFile(
                      value,
                      'appflowy_ai_osx',
                    );
                  },
                ),
                TextField(
                  controller: localLLMPathController
                    ..text = state.localLLMPath ?? '',
                  onSubmitted: (value) {
                    context.read<SettingsAIBloc>().add(
                          SettingsAIEvent.setLocalLLMPath(value),
                        );
                  },
                ),
                TextButton(
                  onPressed: () {
                    if (localLLMPathController.text.isNotEmpty) {
                      context.read<SettingsAIBloc>().add(
                            SettingsAIEvent.setLocalLLMPath(
                              localLLMPathController.text,
                            ),
                          );
                    }
                  },
                  child: const Text('Load LLM'),
                ),
                _buildResult(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResult(SettingsAIState state) {
    final actionResult = state.actionResult;
    if (actionResult == null) {
      return const SizedBox.shrink();
    }
    final result = actionResult.result;
    if (actionResult.isLoading || result == null) {
      return const CircularProgressIndicator();
    }
    return Text(
      result.fold(
        (value) => 'Load LLM Mode Success',
        (error) => 'Load LLM Mode Failed: $error',
      ),
    );
  }

  Future<void> downloadFile(String url, String fileName) async {
    try {
      // Getting the document directory to store the file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final response = await http.get(Uri.parse(url));

      // Checking if the server response is successful
      if (response.statusCode == 200) {
        final file = File(filePath);
        if (!file.existsSync()) {
          await file.create(recursive: true);
        }
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('File downloaded and saved at $filePath');
      } else {
        debugPrint(
          'Failed to download the file: Server responded with status code ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('An error occurred while downloading the file: $e');
    }
  }
}
