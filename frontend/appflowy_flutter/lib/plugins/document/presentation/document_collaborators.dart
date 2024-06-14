import 'package:appflowy/plugins/document/application/document_awareness_metadata.dart';
import 'package:appflowy/plugins/document/application/document_collaborators_bloc.dart';
import 'package:appflowy/plugins/document/presentation/collaborator_avater_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

class DocumentCollaborators extends StatelessWidget {
  const DocumentCollaborators({
    super.key,
    required this.height,
    required this.width,
    required this.view,
    this.padding,
    this.fontSize,
  });

  final ViewPB view;
  final double height;
  final double width;
  final EdgeInsets? padding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DocumentCollaboratorsBloc(view: view)
        ..add(const DocumentCollaboratorsEvent.initial()),
      child: BlocBuilder<DocumentCollaboratorsBloc, DocumentCollaboratorsState>(
        builder: (context, state) {
          final collaborators = state.collaborators;
          if (!state.shouldShowIndicator || collaborators.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: padding ?? EdgeInsets.zero,
            child: CollaboratorAvatarStack(
              height: height,
              width: width,
              borderWidth: 1.0,
              plusWidgetBuilder: (value, border) {
                final lastXCollaborators = collaborators.sublist(
                  collaborators.length - value,
                );
                return BorderedCircleAvatar(
                  border: border,
                  backgroundColor: Theme.of(context).hoverColor,
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FlowyTooltip(
                        message: lastXCollaborators
                            .map((e) => e.userName)
                            .join('\n'),
                        child: FlowyText(
                          '+$value',
                          fontSize: fontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
              avatars: [
                ...collaborators.map(
                  (c) => _UserAvatar(fontSize: fontSize, user: c, width: width),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    this.fontSize,
    required this.user,
    required this.width,
  });

  final DocumentAwarenessMetadata user;
  final double? fontSize;
  final double width;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (isURL(user.userAvatar)) {
      child = _buildUrlAvatar(context);
    } else {
      child = _buildNameAvatar(context);
    }
    return FlowyTooltip(
      message: user.userName,
      child: child,
    );
  }

  Widget _buildNameAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: user.cursorColor.tryToColor(),
      child: FlowyText(
        user.userName.characters.firstOrNull ?? ' ',
        fontSize: fontSize,
        color: Colors.black,
      ),
    );
  }

  Widget _buildUrlAvatar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(width),
      child: CircleAvatar(
        backgroundColor: user.cursorColor.tryToColor(),
        child: Image.network(
          user.userAvatar,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildNameAvatar(context),
        ),
      ),
    );
  }
}
