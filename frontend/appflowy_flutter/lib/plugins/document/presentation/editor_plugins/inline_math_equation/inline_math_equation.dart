import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:provider/provider.dart';

class InlineMathEquationKeys {
  const InlineMathEquationKeys._();

  static const formula = 'formula';
}

class InlineMathEquation extends StatefulWidget {
  const InlineMathEquation({
    super.key,
    required this.formula,
    required this.node,
    required this.index,
    this.textStyle,
  });

  final Node node;
  final int index;
  final String formula;
  final TextStyle? textStyle;

  @override
  State<InlineMathEquation> createState() => _InlineMathEquationState();
}

class _InlineMathEquationState extends State<InlineMathEquation> {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _IgnoreParentPointer(
      child: AppFlowyPopover(
        controller: popoverController,
        direction: PopoverDirection.bottomWithLeftAligned,
        popupBuilder: (_) {
          return MathInputTextField(
            initialText: widget.formula,
            onSubmit: (value) async {
              popoverController.close();
              if (value == widget.formula) {
                return;
              }
              final editorState = context.read<EditorState>();
              final transaction = editorState.transaction
                ..formatText(widget.node, widget.index, 1, {
                  InlineMathEquationKeys.formula: value,
                });
              await editorState.apply(transaction);
            },
          );
        },
        offset: const Offset(0, 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HSpace(2),
                Math.tex(
                  widget.formula,
                  options: MathOptions(
                    style: MathStyle.text,
                    mathFontOptions: const FontOptions(
                      fontShape: FontStyle.italic,
                    ),
                    fontSize: 14.0,
                    color: widget.textStyle?.color ??
                        theme.colorScheme.onSurface,
                  ),
                ),
                const HSpace(2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MathInputTextField extends StatefulWidget {
  const MathInputTextField({
    super.key,
    required this.initialText,
    required this.onSubmit,
  });

  final String initialText;
  final void Function(String value) onSubmit;

  @override
  State<MathInputTextField> createState() => _MathInputTextFieldState();
}

class _MathInputTextFieldState extends State<MathInputTextField> {
  late final TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();

    textEditingController = TextEditingController(
      text: widget.initialText,
    );
    textEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialText.length,
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: FlowyFormTextInput(
              autoFocus: true,
              textAlign: TextAlign.left,
              controller: textEditingController,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              onEditingComplete: () =>
                  widget.onSubmit(textEditingController.text),
            ),
          ),
          const HSpace(4.0),
          FlowyButton(
            text: FlowyText(LocaleKeys.button_done.tr()),
            useIntrinsicWidth: true,
            onTap: () => widget.onSubmit(textEditingController.text),
          ),
        ],
      ),
    );
  }
}

class _IgnoreParentPointer extends StatelessWidget {
  const _IgnoreParentPointer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onTapDown: (_) {},
      onDoubleTap: () {},
      onLongPress: () {},
      child: child,
    );
  }
}
