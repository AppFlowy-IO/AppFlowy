import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

List<ChatMessageMetaPB> metadataPBFromMetadata(Map<String, dynamic>? metadata) {
  final List<ChatMessageMetaPB> context = [];
  if (metadata != null) {
    for (final entry in metadata.entries) {
      if (entry.value is ViewActionPage) {
        if (entry.value.page is ViewPB) {
          final view = entry.value.page as ViewPB;
          if (view.layout.isDocumentView) {
            //
          }
        }
      }
    }
  }

  return context;
}
