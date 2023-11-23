import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FlowyMobileSearchTextField extends StatefulWidget {
  const FlowyMobileSearchTextField({
    super.key,
    required this.onKeywordChanged,
  });

  final void Function(String keyword) onKeywordChanged;

  @override
  State<FlowyMobileSearchTextField> createState() =>
      _FlowyMobileSearchTextFieldState();
}

class _FlowyMobileSearchTextFieldState
    extends State<FlowyMobileSearchTextField> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 36.0,
      ),
      child: FlowyTextField(
        focusNode: focusNode,
        hintText: LocaleKeys.emoji_search.tr(),
        controller: controller,
        onChanged: widget.onKeywordChanged,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            left: 8.0,
            right: 4.0,
          ),
          child: FlowySvg(
            FlowySvgs.search_s,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          maxHeight: 18.0,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(4.0),
          child: FlowyButton(
            text: const FlowySvg(
              FlowySvgs.close_lg,
            ),
            margin: EdgeInsets.zero,
            useIntrinsicWidth: true,
            onTap: () {
              if (controller.text.isNotEmpty) {
                controller.clear();
                widget.onKeywordChanged('');
              } else {
                focusNode.unfocus();
              }
            },
          ),
        ),
      ),
    );
  }
}
