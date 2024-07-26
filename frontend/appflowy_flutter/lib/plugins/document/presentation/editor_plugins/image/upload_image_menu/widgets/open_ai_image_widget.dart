import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class OpenAIImageWidget extends StatefulWidget {
  const OpenAIImageWidget({
    super.key,
    required this.onSelectNetworkImage,
  });

  final void Function(String url) onSelectNetworkImage;

  @override
  State<OpenAIImageWidget> createState() => _OpenAIImageWidgetState();
}

class _OpenAIImageWidgetState extends State<OpenAIImageWidget> {
  Future<FlowyResult<List<String>, AIError>>? future;
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: FlowyTextField(
                hintText: LocaleKeys.document_imageBlock_ai_placeholder.tr(),
                onChanged: (value) => query = value,
                onEditingComplete: _search,
              ),
            ),
            const HSpace(4.0),
            FlowyButton(
              useIntrinsicWidth: true,
              text: FlowyText(
                LocaleKeys.search_label.tr(),
              ),
              onTap: _search,
            ),
          ],
        ),
        const VSpace(12.0),
        if (future != null)
          Expanded(
            child: FutureBuilder(
              future: future,
              builder: (context, value) {
                final data = value.data;
                if (!value.hasData ||
                    value.connectionState != ConnectionState.done ||
                    data == null) {
                  return const CircularProgressIndicator.adaptive();
                }
                return data.fold(
                  (s) => GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 4 / 3,
                    children: s
                        .map(
                          (e) => GestureDetector(
                            onTap: () => widget.onSelectNetworkImage(e),
                            child: Image.network(e),
                          ),
                        )
                        .toList(),
                  ),
                  (e) => Center(
                    child: FlowyText(
                      e.message,
                      maxLines: 3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _search() async {
    final openAI = await getIt.getAsync<AIRepository>();
    setState(() {
      future = openAI.generateImage(
        prompt: query,
        n: 6,
      );
    });
  }
}
