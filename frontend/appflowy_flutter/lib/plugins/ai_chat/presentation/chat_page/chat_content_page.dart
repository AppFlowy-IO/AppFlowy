import 'package:appflowy/plugins/ai_chat/application/ai_chat_prelude.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/load_chat_message_statu_ready.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatContentPage extends StatelessWidget {
  const ChatContentPage({
    super.key,
    required this.view,
    required this.userProfile,
  });

  final UserProfilePB userProfile;
  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return switch (state.loadingState) {
          LoadChatMessageStatus.ready => LoadChatMessageStatusReady(
              view: view,
              userProfile: userProfile,
              chatController: context.read<ChatBloc>().chatController,
            ),
          _ => const Center(child: CircularProgressIndicator.adaptive()),
        };
      },
    );
  }
}
