import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' show Chat, DarkChatTheme;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class AIChatPage extends StatefulWidget {
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
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  @override
  void initState() {
    super.initState();
    _user = types.User(
      id: widget.userProfile.id.toString(),
    );
  }

  late types.User _user;
  final chatTheme = const DarkChatTheme();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: BlocProvider(
          create: (context) => ChatBloc(
            view: widget.view,
            userProfile: widget.userProfile,
          )..add(const ChatEvent.loadMessage()),
          child: BlocListener<ChatBloc, ChatState>(
            listenWhen: (previous, current) =>
                previous.loadingStatus != current.loadingStatus,
            listener: (context, state) {},
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (blocContext, state) {
                return Chat(
                  messages: state.messages,
                  onAttachmentPressed: () {},
                  onMessageTap: (BuildContext _, types.Message message) {
                    blocContext
                        .read<ChatBloc>()
                        .add(ChatEvent.tapMessage(message));
                  },
                  onSendPressed: (types.PartialText message) {
                    // Do nothing. We use the custom input widget.
                    onSendPressed(blocContext, message);
                  },
                  user: _user,
                  theme: chatTheme,
                  customMessageBuilder: (message, {required messageWidth}) {
                    return const SizedBox(
                      width: 100,
                      height: 50,
                      child: CircularProgressIndicator.adaptive(),
                    );
                  },
                  onMessageLongPress:
                      (BuildContext _, types.Message message) {},
                  onEndReached: () async {
                    if (state.hasMore) {
                      state.loadingPreviousStatus.when(
                        loading: () => Log.debug("loading"),
                        finish: () {
                          Log.debug("loading more messages");
                          blocContext
                              .read<ChatBloc>()
                              .add(const ChatEvent.loadMessage());
                        },
                      );
                    } else {
                      Log.debug("no more messages");
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void onSendPressed(
    BuildContext context,
    types.PartialText message,
  ) {
    context.read<ChatBloc>().add(ChatEvent.sendMessage(message.text));
  }
}
