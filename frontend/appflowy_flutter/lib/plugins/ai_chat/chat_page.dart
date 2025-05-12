import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_content_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/chat_bloc.dart';
import 'application/chat_entity.dart';
import 'application/chat_member_bloc.dart';

class AIChatPage extends StatelessWidget {
  const AIChatPage({
    super.key,
    required this.view,
    required this.onDeleted,
    required this.userProfile,
  });

  final ViewPB view;
  final VoidCallback onDeleted;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        /// [ChatBloc] is used to handle chat messages including send/receive message
        BlocProvider(
          create: (_) => ChatBloc(
            chatId: view.id,
            userId: userProfile.id.toString(),
          ),
        ),

        /// [AIPromptInputBloc] is used to handle the user prompt
        BlocProvider(
          create: (_) => AIPromptInputBloc(
            objectId: view.id,
            predefinedFormat: PredefinedFormat(
              imageFormat: ImageFormat.text,
              textFormat: TextFormat.bulletList,
            ),
          ),
        ),
        BlocProvider(create: (_) => ChatMemberBloc()),
      ],
      child: Builder(
        builder: (context) {
          return DropTarget(
            onDragDone: (DropDoneDetails detail) async {
              if (context.read<AIPromptInputBloc>().state.supportChatWithFile) {
                for (final file in detail.files) {
                  context
                      .read<AIPromptInputBloc>()
                      .add(AIPromptInputEvent.attachFile(file.path, file.name));
                }
              }
            },
            child: FocusScope(
              onKeyEvent: (focusNode, event) {
                if (event is! KeyUpEvent) {
                  return KeyEventResult.ignored;
                }

                if (event.logicalKey == LogicalKeyboardKey.escape ||
                    event.logicalKey == LogicalKeyboardKey.keyC &&
                        HardwareKeyboard.instance.isControlPressed) {
                  final chatBloc = context.read<ChatBloc>();
                  if (chatBloc.state.promptResponseState !=
                      PromptResponseState.ready) {
                    chatBloc.add(ChatEvent.stopStream());
                    return KeyEventResult.handled;
                  }
                }

                return KeyEventResult.ignored;
              },
              child: ChatContentPage(
                view: view,
                userProfile: userProfile,
              ),
            ),
          );
        },
      ),
    );
  }
}
