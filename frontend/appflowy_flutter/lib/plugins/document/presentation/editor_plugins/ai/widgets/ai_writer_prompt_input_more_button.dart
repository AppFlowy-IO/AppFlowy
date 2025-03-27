import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/colorscheme/default_colorscheme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import '../operations/ai_writer_entities.dart';

class AiWriterPromptMoreButton extends StatelessWidget {
  const AiWriterPromptMoreButton({
    super.key,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
  });

  final bool isEnabled;
  final bool isSelected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isEnabled,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: DesktopAIPromptSizes.actionBarButtonSize,
          child: FlowyHover(
            style: const HoverStyle(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            isSelected: () => isSelected,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 4, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlowyText(
                    LocaleKeys.ai_more.tr(),
                    fontSize: 12,
                    figmaLineHeight: 16,
                    color: isEnabled
                        ? Theme.of(context).hintColor
                        : Theme.of(context).disabledColor,
                  ),
                  const HSpace(2.0),
                  FlowySvg(
                    FlowySvgs.ai_source_drop_down_s,
                    color: Theme.of(context).hintColor,
                    size: const Size.square(8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoreAiWriterCommands extends StatelessWidget {
  const MoreAiWriterCommands({
    super.key,
    required this.hasSelection,
    required this.editorState,
    required this.onSelectCommand,
  });

  final EditorState editorState;
  final bool hasSelection;
  final void Function(AiWriterCommand) onSelectCommand;

  @override
  Widget build(BuildContext context) {
    return Container(
      // add one here to take into account the border of the main message box.
      // It is configured to be on the outside to hide some graphical
      // artifacts.
      margin: EdgeInsets.only(top: 4.0 + 1.0),
      padding: EdgeInsets.all(8.0),
      constraints: BoxConstraints(minWidth: 240.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.light
              ? ColorSchemeConstants.lightBorderColor
              : ColorSchemeConstants.darkBorderColor,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        boxShadow: Theme.of(context).isLightMode
            ? ShadowConstants.lightSmall
            : ShadowConstants.darkSmall,
      ),
      child: IntrinsicWidth(
        child: Column(
          spacing: 4.0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _getCommands(
            hasSelection: hasSelection,
          ),
        ),
      ),
    );
  }

  List<Widget> _getCommands({required bool hasSelection}) {
    if (hasSelection) {
      return [
        _bottomButton(AiWriterCommand.improveWriting),
        _bottomButton(AiWriterCommand.fixSpellingAndGrammar),
        _bottomButton(AiWriterCommand.explain),
        const Divider(height: 1.0, thickness: 1.0),
        _bottomButton(AiWriterCommand.makeLonger),
        _bottomButton(AiWriterCommand.makeShorter),
      ];
    } else {
      return [
        _bottomButton(AiWriterCommand.continueWriting),
      ];
    }
  }

  Widget _bottomButton(AiWriterCommand command) {
    return Builder(
      builder: (context) {
        return FlowyButton(
          leftIcon: FlowySvg(
            command.icon,
            size: const Size.square(16),
            color: Theme.of(context).iconTheme.color,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          text: FlowyText(
            command.i18n,
            figmaLineHeight: 20,
          ),
          onTap: () => onSelectCommand(command),
        );
      },
    );
  }
}
