import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/openai_client.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

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
  Future<Either<OpenAIError, List<String>>>? future;
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
                autoFocus: true,
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
                  (l) => Center(
                    child: FlowyText(
                      l.message,
                      maxLines: 3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  (r) => GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 4 / 3,
                    children: r
                        .map(
                          (e) => GestureDetector(
                            onTap: () => widget.onSelectNetworkImage(e),
                            child: Image.network(e),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  void _search() async {
    final openAI = await getIt.getAsync<OpenAIRepository>();
    setState(() {
      future = openAI.generateImage(
        prompt: query,
        n: 6,
      );
    });
  }
}
