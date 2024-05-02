import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_close_keyboard_or_menu_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/appflowy_mobile_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/keyboard_height_observer.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

abstract class AppFlowyMobileToolbarWidgetService {
  void closeItemMenu();
  void closeKeyboard();

  PropertyValueNotifier<bool> get showMenuNotifier;
}

class AppFlowyMobileToolbar extends StatefulWidget {
  const AppFlowyMobileToolbar({
    super.key,
    this.toolbarHeight = 50.0,
    required this.editorState,
    required this.toolbarItemsBuilder,
    required this.child,
  });

  final EditorState editorState;
  final double toolbarHeight;
  final List<AppFlowyMobileToolbarItem> Function(
    Selection? selection,
  ) toolbarItemsBuilder;
  final Widget child;

  @override
  State<AppFlowyMobileToolbar> createState() => _AppFlowyMobileToolbarState();
}

class _AppFlowyMobileToolbarState extends State<AppFlowyMobileToolbar> {
  OverlayEntry? toolbarOverlay;

  final isKeyboardShow = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    _insertKeyboardToolbar();
    KeyboardHeightObserver.instance.addListener(_onKeyboardHeightChanged);
  }

  @override
  void dispose() {
    _removeKeyboardToolbar();
    KeyboardHeightObserver.instance.removeListener(_onKeyboardHeightChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        // add a bottom offset to make sure the toolbar is above the keyboard
        ValueListenableBuilder(
          valueListenable: isKeyboardShow,
          builder: (context, isKeyboardShow, __) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              height: isKeyboardShow ? widget.toolbarHeight : 0,
            );
          },
        ),
      ],
    );
  }

  void _onKeyboardHeightChanged(double height) {
    isKeyboardShow.value = height > 0;
  }

  void _removeKeyboardToolbar() {
    toolbarOverlay?.remove();
    toolbarOverlay?.dispose();
    toolbarOverlay = null;
  }

  void _insertKeyboardToolbar() {
    _removeKeyboardToolbar();

    Widget child = ValueListenableBuilder<Selection?>(
      valueListenable: widget.editorState.selectionNotifier,
      builder: (_, Selection? selection, __) {
        // if the selection is null, hide the toolbar
        if (selection == null ||
            widget.editorState.selectionExtraInfo?[
                    selectionExtraInfoDisableMobileToolbarKey] ==
                true) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: BlocProvider.value(
            value: context.read<DocumentBloc>(),
            child: _MobileToolbar(
              editorState: widget.editorState,
              toolbarItems: widget.toolbarItemsBuilder(selection),
              toolbarHeight: widget.toolbarHeight,
            ),
          ),
        );
      },
    );

    child = Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            child: child,
          ),
        ),
      ],
    );

    final router = GoRouter.of(context);

    toolbarOverlay = OverlayEntry(
      builder: (context) {
        return Provider.value(
          value: router,
          child: child,
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Overlay.of(context, rootOverlay: true).insert(toolbarOverlay!);
    });
  }
}

class _MobileToolbar extends StatefulWidget {
  const _MobileToolbar({
    required this.editorState,
    required this.toolbarItems,
    required this.toolbarHeight,
  });

  final EditorState editorState;
  final List<AppFlowyMobileToolbarItem> toolbarItems;
  final double toolbarHeight;

  @override
  State<_MobileToolbar> createState() => _MobileToolbarState();
}

class _MobileToolbarState extends State<_MobileToolbar>
    implements AppFlowyMobileToolbarWidgetService {
  // used to control the toolbar menu items
  @override
  PropertyValueNotifier<bool> showMenuNotifier = PropertyValueNotifier(false);

  // when the users click the menu item, the keyboard will be hidden,
  //  but in this case, we don't want to update the cached keyboard height.
  // This is because we want to keep the same height when the menu is shown.
  bool canUpdateCachedKeyboardHeight = true;
  ValueNotifier<double> cachedKeyboardHeight = ValueNotifier(0.0);

  // used to check if click the same item again
  int? selectedMenuIndex;

  Selection? currentSelection;

  bool closeKeyboardInitiative = false;

  final ScrollOffsetListener offsetListener = ScrollOffsetListener.create();
  late final StreamSubscription offsetSubscription;
  ValueNotifier<double> toolbarOffset = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();

    currentSelection = widget.editorState.selection;
    KeyboardHeightObserver.instance.addListener(_onKeyboardHeightChanged);
    offsetSubscription = offsetListener.changes.listen((event) {
      toolbarOffset.value += event;
    });
  }

  @override
  void didUpdateWidget(covariant _MobileToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (currentSelection != widget.editorState.selection) {
      currentSelection = widget.editorState.selection;
      closeItemMenu();
      if (currentSelection != null) {
        _showKeyboard();
      }
    }
  }

  @override
  void dispose() {
    showMenuNotifier.dispose();
    cachedKeyboardHeight.dispose();
    KeyboardHeightObserver.instance.removeListener(_onKeyboardHeightChanged);
    offsetSubscription.cancel();
    toolbarOffset.dispose();

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();

    canUpdateCachedKeyboardHeight = true;
    closeItemMenu();
    _closeKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    // toolbar
    //  - if the menu is shown, the toolbar will be pushed up by the height of the menu
    //  - otherwise, add a spacer to push the toolbar up when the keyboard is shown
    return Column(
      children: [
        const Divider(
          height: 0.5,
          color: Color(0xFFEDEDED),
        ),
        _buildToolbar(context),
        const Divider(
          height: 0.5,
          color: Color(0xFFEDEDED),
        ),
        _buildMenuOrSpacer(context),
      ],
    );
  }

  @override
  void closeItemMenu() {
    showMenuNotifier.value = false;
  }

  @override
  void closeKeyboard() {
    _closeKeyboard();
  }

  void showItemMenu() {
    showMenuNotifier.value = true;
  }

  void _onKeyboardHeightChanged(double height) {
    // if the keyboard is not closed initiative, we need to close the menu at same time
    if (!closeKeyboardInitiative &&
        cachedKeyboardHeight.value != 0 &&
        height == 0) {
      widget.editorState.selection = null;
    }

    // if the menu is shown and the height is not 0, we need to close the menu
    if (showMenuNotifier.value && height != 0) {
      closeItemMenu();
    }

    if (canUpdateCachedKeyboardHeight) {
      cachedKeyboardHeight.value = height;
    }

    if (height == 0) {
      closeKeyboardInitiative = false;
    }
  }

  // toolbar list view and close keyboard/menu button
  Widget _buildToolbar(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    return Container(
      height: widget.toolbarHeight,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: theme.toolbarBackgroundColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F181818),
            blurRadius: 40,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // toolbar list view
          Expanded(
            child: _ToolbarItemListView(
              offsetListener: offsetListener,
              toolbarItems: widget.toolbarItems,
              editorState: widget.editorState,
              toolbarWidgetService: this,
              itemWithActionOnPressed: (_) {
                if (showMenuNotifier.value) {
                  closeItemMenu();
                  _showKeyboard();
                  // update the cached keyboard height after the keyboard is shown
                  Debounce.debounce('canUpdateCachedKeyboardHeight',
                      const Duration(milliseconds: 500), () {
                    canUpdateCachedKeyboardHeight = true;
                  });
                }
              },
              itemWithMenuOnPressed: (index) {
                // click the same one
                if (selectedMenuIndex == index && showMenuNotifier.value) {
                  // if the menu is shown, close it and show the keyboard
                  closeItemMenu();
                  _showKeyboard();
                  // update the cached keyboard height after the keyboard is shown
                  Debounce.debounce('canUpdateCachedKeyboardHeight',
                      const Duration(milliseconds: 500), () {
                    canUpdateCachedKeyboardHeight = true;
                  });
                } else {
                  canUpdateCachedKeyboardHeight = false;
                  selectedMenuIndex = index;
                  showItemMenu();
                  closeKeyboardInitiative = true;
                  _closeKeyboard();
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13.0),
            child: VerticalDivider(
              width: 1.0,
              thickness: 1.0,
              color: Color(0xFFD9D9D9),
            ),
          ),
          // close menu or close keyboard button
          CloseKeyboardOrMenuButton(
            onPressed: () {
              closeKeyboardInitiative = true;
              // close the keyboard and clear the selection
              // if the selection is null, the keyboard and the toolbar will be hidden automatically
              widget.editorState.selection = null;

              // sometimes, the keyboard is not closed after the selection is cleared
              if (Platform.isAndroid) {
                SystemChannels.textInput.invokeMethod('TextInput.hide');
              }
            },
          ),
          const HSpace(4.0),
        ],
      ),
    );
  }

  // if there's no menu, we need to add a spacer to push the toolbar up when the keyboard is shown
  Widget _buildMenuOrSpacer(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: cachedKeyboardHeight,
      builder: (_, height, ___) {
        return AnimatedContainer(
          duration: const Duration(microseconds: 110),
          height: height,
          child: ValueListenableBuilder(
            valueListenable: showMenuNotifier,
            builder: (_, showingMenu, __) {
              return AnimatedContainer(
                duration: const Duration(microseconds: 110),
                height: height,
                child: (showingMenu && selectedMenuIndex != null)
                    ? widget.toolbarItems[selectedMenuIndex!].menuBuilder?.call(
                          context,
                          widget.editorState,
                          this,
                        ) ??
                        const SizedBox.shrink()
                    : const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }

  void _showKeyboard() {
    final selection = widget.editorState.selection;
    if (selection != null) {
      widget.editorState.service.keyboardService?.enableKeyBoard(selection);
    }
  }

  void _closeKeyboard() {
    widget.editorState.service.keyboardService?.closeKeyboard();
  }
}

class _ToolbarItemListView extends StatefulWidget {
  const _ToolbarItemListView({
    required this.offsetListener,
    required this.toolbarItems,
    required this.editorState,
    required this.toolbarWidgetService,
    required this.itemWithMenuOnPressed,
    required this.itemWithActionOnPressed,
  });

  final Function(int index) itemWithMenuOnPressed;
  final Function(int index) itemWithActionOnPressed;
  final List<AppFlowyMobileToolbarItem> toolbarItems;
  final EditorState editorState;
  final AppFlowyMobileToolbarWidgetService toolbarWidgetService;
  final ScrollOffsetListener offsetListener;

  @override
  State<_ToolbarItemListView> createState() => _ToolbarItemListViewState();
}

class _ToolbarItemListViewState extends State<_ToolbarItemListView> {
  final scrollController = ItemScrollController();
  Selection? previousSelection;

  @override
  void initState() {
    super.initState();

    widget.editorState.selectionNotifier
        .addListener(_debounceUpdatePilotPosition);
    previousSelection = widget.editorState.selection;
  }

  @override
  void dispose() {
    widget.editorState.selectionNotifier
        .removeListener(_debounceUpdatePilotPosition);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const left = 8.0;
    const right = 4.0;
    // 68.0 is the width of the close keyboard/menu button
    final padding = _calculatePadding(left + right + 68.0);

    final children = [
      const HSpace(left),
      ...widget.toolbarItems
          .mapIndexed(
            (index, element) => element.itemBuilder.call(
              context,
              widget.editorState,
              widget.toolbarWidgetService,
              element.menuBuilder != null
                  ? () {
                      widget.itemWithMenuOnPressed(index);
                    }
                  : null,
              element.menuBuilder == null
                  ? () {
                      widget.itemWithActionOnPressed(index);
                    }
                  : null,
            ),
          )
          .map((e) => [e, HSpace(padding)])
          .flattened,
      const HSpace(right),
    ];

    return PageStorage(
      bucket: PageStorageBucket(),
      child: ScrollablePositionedList.builder(
        physics: const ClampingScrollPhysics(),
        scrollOffsetListener: widget.offsetListener,
        itemScrollController: scrollController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => children[index],
        itemCount: children.length,
      ),
    );
  }

  double _calculatePadding(double extent) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth - extent;
    final int count;
    if (screenWidth <= 340) {
      count = 5;
    } else if (screenWidth <= 384) {
      count = 6;
    } else if (screenWidth <= 430) {
      count = 7;
    } else {
      count = 8;
    }
    // left + item count * width + item count * padding + right + close button width = screenWidth
    return (width - count * 40.0) / count;
  }

  void _debounceUpdatePilotPosition() {
    Debounce.debounce(
      'updatePilotPosition',
      const Duration(milliseconds: 250),
      _updatePilotPosition,
    );
  }

  void _updatePilotPosition() {
    final selection = widget.editorState.selection;
    if (selection == null) {
      return;
    }

    if (previousSelection != null &&
        previousSelection!.isCollapsed == selection.isCollapsed) {
      return;
    }

    final toolbarItems = widget.toolbarItems;
    // use -0.4 to make sure the pilot is in the front of the toolbar item
    final alignment = selection.isCollapsed ? 0.0 : -0.4;
    final index = toolbarItems.indexWhere(
      (element) => selection.isCollapsed
          ? element.pilotAtCollapsedSelection
          : element.pilotAtExpandedSelection,
    );
    if (index != -1) {
      scrollController.scrollTo(
        alignment: alignment,
        index: index,
        duration: const Duration(
          milliseconds: 250,
        ),
      );
    }

    previousSelection = selection;
  }
}
