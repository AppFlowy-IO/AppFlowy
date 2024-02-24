import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/stability_ai/stability_ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/stability_ai/stability_ai_error.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StabilityAIImageWidget extends StatefulWidget {
  const StabilityAIImageWidget({
    super.key,
    required this.onSelectImage,
  });

  final void Function(String url) onSelectImage;

  @override
  State<StabilityAIImageWidget> createState() => _StabilityAIImageWidgetState();
}

class _StabilityAIImageWidgetState extends State<StabilityAIImageWidget> {
  Future<FlowyResult<List<String>, StabilityAIRequestError>>? future;
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
                hintText: LocaleKeys
                    .document_imageBlock_stability_ai_placeholder
                    .tr(),
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
                    children: s.map(
                      (e) {
                        final base64Image = base64Decode(e);
                        return GestureDetector(
                          onTap: () async {
                            final tempDirectory = await getTemporaryDirectory();
                            final path = p.join(
                              tempDirectory.path,
                              '${uuid()}.png',
                            );
                            File(path).writeAsBytesSync(base64Image);
                            widget.onSelectImage(path);
                          },
                          child: Image.memory(base64Image),
                        );
                      },
                    ).toList(),
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
    final stabilityAI = await getIt.getAsync<StabilityAIRepository>();
    setState(() {
      future = stabilityAI.generateImage(
        prompt: query,
        n: 6,
      );
    });
  }
}
