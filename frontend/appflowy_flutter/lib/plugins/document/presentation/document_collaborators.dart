import 'package:appflowy/plugins/document/application/document_collaborators_bloc.dart';
import 'package:appflowy/plugins/document/presentation/collaborator_avater_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
              avatars: collaborators
                  .map(
                    (c) => FlowyTooltip(
                      message: c.userName,
                      child: CircleAvatar(
                        backgroundColor: c.cursorColor.tryToColor(),
                        child: FlowyText(
                          c.userName.characters.firstOrNull ?? ' ',
                          fontSize: fontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
