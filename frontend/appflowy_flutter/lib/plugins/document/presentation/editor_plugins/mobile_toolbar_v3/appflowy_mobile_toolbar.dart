import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/appflowy_mobile_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/keyboard_height_observer.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const String disableMobileToolbarKey = 'disableMobileToolbar';

class AppFlowyMobileToolbar extends StatefulWidget {
  const AppFlowyMobileToolbar({
    super.key,
    this.toolbarHeight = 50.0,
    required this.editorState,
    required this.toolbarItems,
    required this.child,
  });

  final EditorState editorState;
  final double toolbarHeight;
  final List<AppFlowyMobileToolbarItem> toolbarItems;
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
        Expanded(
          child: widget.child,
        ),
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
            widget.editorState.selectionExtraInfo?[disableMobileToolbarKey] ==
                true) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: _MobileToolbar(
            editorState: widget.editorState,
            toolbarItems: widget.toolbarItems,
            toolbarHeight: widget.toolbarHeight,
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

    toolbarOverlay = OverlayEntry(
      builder: (context) {
        return child;
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
    implements MobileToolbarWidgetService {
  // used to control the toolbar menu items
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

  @override
  void initState() {
    super.initState();

    currentSelection = widget.editorState.selection;
    KeyboardHeightObserver.instance.addListener(_onKeyboardHeightChanged);
  }

  @override
  void didUpdateWidget(covariant _MobileToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (currentSelection != widget.editorState.selection) {
      currentSelection = widget.editorState.selection;
      closeItemMenu();
    }
  }

  @override
  void dispose() {
    showMenuNotifier.dispose();
    cachedKeyboardHeight.dispose();
    KeyboardHeightObserver.instance.removeListener(_onKeyboardHeightChanged);

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
        _buildToolbar(context),
        _buildMenuOrSpacer(context),
        // for debug
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  void closeItemMenu() {
    showMenuNotifier.value = false;
  }

  void showItemMenu() {
    showMenuNotifier.value = true;
  }

  void _onKeyboardHeightChanged(double height) {
    if (canUpdateCachedKeyboardHeight) {
      cachedKeyboardHeight.value = height;
    }

    // if the keyboard is not closed initiative, we need to close the menu at same time
    if (!closeKeyboardInitiative &&
        cachedKeyboardHeight.value != 0 &&
        height == 0) {
      widget.editorState.selection = null;
    }

    if (height == 0) {
      closeKeyboardInitiative = false;
    }
  }

  // toolbar list view and close keyboard/menu button
  Widget _buildToolbar(BuildContext context) {
    return Container(
      color: Colors.grey,
      height: widget.toolbarHeight,
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // toolbar list view
          Expanded(
            child: _ToolbarItemListView(
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
          // divider
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: VerticalDivider(
              width: 1,
            ),
          ),
          // close menu or close keyboard button
          ValueListenableBuilder(
            valueListenable: showMenuNotifier,
            builder: (_, showingMenu, __) {
              return _CloseKeyboardOrMenuButton(
                showingMenu: showingMenu,
                onPressed: () {
                  if (showingMenu) {
                    // close the menu and show the keyboard
                    closeItemMenu();
                    _showKeyboard();
                  } else {
                    closeKeyboardInitiative = true;
                    // close the keyboard and clear the selection
                    // if the selection is null, the keyboard and the toolbar will be hidden automatically
                    widget.editorState.selection = null;
                  }
                },
              );
            },
          ),
          const SizedBox(
            width: 4.0,
          ),
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

class _ToolbarItemListView extends StatelessWidget {
  const _ToolbarItemListView({
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
  final MobileToolbarWidgetService toolbarWidgetService;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final toolbarItem = toolbarItems[index];
        return toolbarItem.itemBuilder.call(
          context,
          editorState,
          toolbarItem.menuBuilder != null
              ? () {
                  itemWithMenuOnPressed(index);
                }
              : null,
          toolbarItem.menuBuilder == null
              ? () {
                  itemWithActionOnPressed(index);
                }
              : null,
        );
      },
      itemCount: toolbarItems.length,
      scrollDirection: Axis.horizontal,
    );
  }
}

class _CloseKeyboardOrMenuButton extends StatelessWidget {
  const _CloseKeyboardOrMenuButton({
    required this.showingMenu,
    required this.onPressed,
  });

  final bool showingMenu;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      useIntrinsicWidth: true,
      text: showingMenu
          ? const AFMobileIcon(
              afMobileIcons: AFMobileIcons.close,
            )
          : const Icon(
              Icons.keyboard_hide,
            ),
    );
  }
}
