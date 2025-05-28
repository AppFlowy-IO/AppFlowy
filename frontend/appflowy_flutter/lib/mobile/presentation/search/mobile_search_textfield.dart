import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/mobile_bottom_navigation_bar.dart';
import 'package:appflowy/shared/popup_menu/appflowy_popup_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/af_navigator_observer.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'mobile_search_page.dart';

class MobileSearchTextfield extends StatefulWidget {
  const MobileSearchTextfield({
    super.key,
    this.onChanged,
    required this.hintText,
    required this.query,
    required this.focusNode,
  });

  final String hintText;
  final String query;
  final ValueChanged<String>? onChanged;
  final FocusNode focusNode;

  @override
  State<MobileSearchTextfield> createState() => _MobileSearchTextfieldState();
}

class _MobileSearchTextfieldState extends State<MobileSearchTextfield>
    with RouteAware {
  late final TextEditingController controller;

  FocusNode get focusNode => widget.focusNode;
  late String lastPage = bottomNavigationBarItemType.value ?? '';
  String lastText = '';

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.query);
    controller.addListener(() {
      if (!mounted) return;
      if (lastText != controller.text) {
        widget.onChanged?.call(controller.text);
        lastText = controller.text;
      }
    });
    bottomNavigationBarItemType.addListener(onBackOrLeave);
    makeSureHasFocus();
    getIt<AFNavigatorObserver>().addListener(onRoute);
  }

  @override
  void dispose() {
    controller.dispose();
    bottomNavigationBarItemType.removeListener(onBackOrLeave);
    getIt<AFNavigatorObserver>().removeListener(onRoute);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      height: 42,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.only(left: 4, right: 16),
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, _, __) {
          return Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (lastPage.isEmpty) return;
                  // close the popup menu
                  closePopupMenu();
                  try {
                    BottomNavigationBarItemType label =
                        BottomNavigationBarItemType.values.byName(lastPage);
                    if (label == BottomNavigationBarItemType.search) {
                      label = BottomNavigationBarItemType.home;
                    }
                    if (label == BottomNavigationBarItemType.notification) {
                      getIt<ReminderBloc>().add(const ReminderEvent.refresh());
                    }
                    bottomNavigationBarItemType.value = label.label;
                    final routeName = label.routeName;
                    if (routeName != null) GoRouter.of(context).go(routeName);
                  } on ArgumentError {
                    Log.error(
                      'lastPage: [$lastPage] cannot be converted to BottomNavigationBarItemType',
                    );
                  }
                },
                child: SizedBox.square(
                  dimension: 40,
                  child: Center(
                    child: FlowySvg(
                      FlowySvgs.search_page_arrow_left_m,
                      size: Size.square(20),
                      color: theme.iconColorScheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  focusNode: focusNode,
                  textAlign: TextAlign.left,
                  controller: controller,
                  style: theme.textStyle.heading4.standard(
                    color: theme.textColorScheme.primary,
                  ),
                  decoration: buildInputDecoration(context),
                ),
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
      borderSide: BorderSide(color: theme.borderColorScheme.primary),
    );
    final enableBorder = border.copyWith(
      borderSide: BorderSide(color: theme.borderColorScheme.themeThick),
    );
    final hintStyle = theme.textStyle.heading4.standard(
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
      prefixIconConstraints: BoxConstraints.loose(Size(38, 40)),
      prefixIcon: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
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
                  FlowySvgs.search_clear_m,
                  color: theme.iconColorScheme.tertiary,
                  size: const Size.square(20),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> makeSureHasFocus() async {
    if (!mounted || focusNode.hasFocus) return;
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      makeSureHasFocus();
    });
  }

  void onBackOrLeave() {
    final label = bottomNavigationBarItemType.value;
    if (label == BottomNavigationBarItemType.search.label) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
      controller.clear();
      lastPage = label ?? '';
    }
  }

  void onRoute(RouteInfo routeInfo) {
    final oldName = routeInfo.oldRoute?.settings.name;
    if (oldName != MobileSearchScreen.routeName) return;
    if (routeInfo is PushRouterInfo) {
      focusNode.unfocus();
    }
  }
}
