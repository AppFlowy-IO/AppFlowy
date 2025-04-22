import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/mobile_bottom_navigation_bar.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MobileSearchTextfield extends StatefulWidget {
  const MobileSearchTextfield({
    super.key,
    this.onChanged,
    required this.hintText,
    required this.query,
  });

  final String hintText;
  final String query;
  final ValueChanged<String>? onChanged;

  @override
  State<MobileSearchTextfield> createState() => _MobileSearchTextfieldState();
}

class _MobileSearchTextfieldState extends State<MobileSearchTextfield> {
  late final TextEditingController controller;
  late final FocusNode focusNode;
  final ValueNotifier<bool> hasFocusValueNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.query);
    focusNode = FocusNode();
    focusNode.addListener(() {
      if (!mounted) return;
      hasFocusValueNotifier.value = focusNode.hasFocus;
    });
    controller.addListener(() {
      if (!mounted) return;
      widget.onChanged?.call(controller.text);
    });
    bottomNavigationBarItemType.addListener(onBackOrLeave);
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    hasFocusValueNotifier.dispose();
    bottomNavigationBarItemType.removeListener(onBackOrLeave);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return SizedBox(
      height: 40,
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, _, __) {
          final hasText = controller.text.isNotEmpty;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  autofocus: true,
                  focusNode: focusNode,
                  textAlign: TextAlign.left,
                  controller: controller,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: theme.textColorScheme.primary,
                  ),
                  decoration: buildInputDecoration(context),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: hasFocusValueNotifier,
                builder: (context, hasFocus, __) {
                  if (!hasFocus || !hasText) return SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => focusNode.unfocus(),
                    child: Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        LocaleKeys.button_cancel.tr(),
                        style: theme.textStyle.body
                            .standard(color: theme.textColorScheme.action),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration buildInputDecoration(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final showCancelIcon = controller.text.isNotEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: theme.borderColorScheme.greyTertiary),
    );
    final enableBorder = border.copyWith(
      borderSide: BorderSide(color: theme.borderColorScheme.themeThick),
    );
    final hintStyle = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      color: theme.textColorScheme.tertiary,
    );
    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: hintStyle,
      contentPadding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      isDense: true,
      border: border,
      enabledBorder: border,
      focusedBorder: enableBorder,
      prefixIconConstraints: BoxConstraints.loose(Size(34, 40)),
      prefixIcon: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
        child: FlowySvg(
          FlowySvgs.m_home_search_icon_m,
          color: theme.iconColorScheme.secondary,
          size: Size.square(20),
        ),
      ),
      suffixIconConstraints:
          showCancelIcon ? BoxConstraints.loose(Size(34, 40)) : null,
      suffixIcon: showCancelIcon
          ? GestureDetector(
              onTap: () {
                controller.clear();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
                child: FlowySvg(
                  FlowySvgs.clear_s,
                  blendMode: null,
                  color: theme.iconColorScheme.tertiary,
                  size: Size.square(20),
                ),
              ),
            )
          : null,
    );
  }

  void onBackOrLeave() {
    final lable = bottomNavigationBarItemType.value;
    if (lable == BottomNavigationBarItemType.search.label) {
      focusNode.requestFocus();
    } else {
      controller.clear();
    }
  }
}
