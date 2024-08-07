import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

Future<List<ChatMessageMetaPB>> metadataPBFromMetadata(
  Map<String, dynamic>? map,
) async {
  final List<ChatMessageMetaPB> metadata = [];
  if (map != null) {
    for (final entry in map.entries) {
      if (entry.value is ViewActionPage) {
        if (entry.value.page is ViewPB) {
          final view = entry.value.page as ViewPB;
          if (view.layout.isDocumentView) {
            final payload = OpenDocumentPayloadPB(documentId: view.id);
            final result = await DocumentEventGetDocumentText(payload).send();
            result.fold((pb) {
              metadata.add(
                ChatMessageMetaPB(
                  id: view.id,
                  name: view.name,
                  text: pb.text,
                  source: "appflowy document",
                ),
              );
            }, (err) {
              Log.error('Failed to get document text: $err');
            });
          }
        }
      }
    }
  }

  return metadata;
}
