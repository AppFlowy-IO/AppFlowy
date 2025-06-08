import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

mixin AFDropDownMenuMixin {
  String get label;
}

typedef DropDownMenuItemBuilder<T extends AFDropDownMenuMixin> = Widget
    Function(
  BuildContext context,
  T item,
  bool isSelected,
  ValueChanged<T>? onSelected,
);

class AFDropDownMenu<T extends AFDropDownMenuMixin> extends StatefulWidget {
  const AFDropDownMenu({
    super.key,
    required this.items,
    required this.selectedItems,
    this.onSelected,
    this.closeOnSelect,
    this.controller,
    this.isClearEnabled = true,
    this.errorText,
    this.isRequired = false,
    this.isDisabled = false,
    this.emptyLabel,
    this.clearIcon,
    this.dropdownIcon,
    this.selectedIcon,
    this.itemBuilder,
  });

  final List<T> items;
  final List<T> selectedItems;
  final void Function(T? value)? onSelected;
  final bool? closeOnSelect;
  final AFPopoverController? controller;
  final String? errorText;
  final bool isRequired;
  final bool isDisabled;
  final bool isMultiselect = false;
  final bool isClearEnabled;
  final String? emptyLabel;
  final Widget? clearIcon;
  final Widget? dropdownIcon;
  final Widget? selectedIcon;
  final DropDownMenuItemBuilder<T>? itemBuilder;

  @override
  State<AFDropDownMenu<T>> createState() => _AFDropDownMenuState<T>();
}

class _AFDropDownMenuState<T extends AFDropDownMenuMixin>
    extends State<AFDropDownMenu<T>> {
  late final AFPopoverController controller;
  bool isHovering = false;
  bool isOpen = false;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? AFPopoverController();
    controller.addListener(popoverListener);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      controller.dispose();
    } else {
      controller.removeListener(popoverListener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return AFPopover(
          controller: controller,
          padding: EdgeInsets.zero,
          anchor: AFAnchor(
            childAlignment: Alignment.topCenter,
            overlayAlignment: Alignment.bottomCenter,
            offset: Offset(0, theme.spacing.xs),
          ),
          decoration: BoxDecoration(
            color: theme.surfaceColorScheme.layer01,
            borderRadius: BorderRadius.circular(theme.borderRadius.m),
            boxShadow: theme.shadow.small,
          ),
          popover: (popoverContext) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: 300,
              ),
              child: _DropdownPopoverContents(
                items: widget.items,
                onSelected: (item) {
                  widget.onSelected?.call(item);
                  if ((widget.closeOnSelect == null && !widget.isMultiselect) ||
                      widget.closeOnSelect == true) {
                    controller.hide();
                  }
                },
                selectedItems: widget.selectedItems,
                selectedIcon: widget.selectedIcon,
                isMultiselect: widget.isMultiselect,
                itemBuilder: widget.itemBuilder,
              ),
            );
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => isHovering = true),
            onExit: (_) => setState(() => isHovering = false),
            child: GestureDetector(
              onTap: () {
                if (widget.isDisabled) {
                  return;
                }
                if (controller.isOpen) {
                  controller.hide();
                } else {
                  controller.show();
                }
              },
              child: Container(
                constraints: const BoxConstraints.tightFor(height: 32),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isDisabled
                        ? theme.borderColorScheme.primary
                        : isOpen
                            ? theme.borderColorScheme.themeThick
                            : isHovering
                                ? theme.borderColorScheme.primaryHover
                                : theme.borderColorScheme.primary,
                  ),
                  color: widget.isDisabled
                      ? theme.fillColorScheme.contentHover
                      : null,
                  borderRadius: BorderRadius.circular(theme.borderRadius.m),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.m,
                  vertical: theme.spacing.xs,
                ),
                child: Row(
                  spacing: theme.spacing.xs,
                  children: [
                    Expanded(
                      child: _DropdownButtonContents(
                        items: widget.selectedItems,
                        isMultiselect: widget.isMultiselect,
                        isDisabled: widget.isDisabled,
                        emptyLabel: widget.emptyLabel,
                      ),
                    ),
                    if (widget.isClearEnabled &&
                        isOpen &&
                        widget.clearIcon != null)
                      widget.clearIcon!,
                    widget.dropdownIcon ??
                        SizedBox.square(
                          dimension: 20,
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void popoverListener() {
    setState(() {
      isOpen = controller.isOpen;
    });
  }
}

class _DropdownButtonContents<T extends AFDropDownMenuMixin>
    extends StatelessWidget {
  const _DropdownButtonContents({
    super.key,
    required this.items,
    this.isDisabled = false,
    this.isMultiselect = false,
    this.emptyLabel,
  });

  final List<T> items;
  final bool isMultiselect;
  final bool isDisabled;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    if (isMultiselect) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          spacing: theme.spacing.xs,
          children: [
            ...items.map((item) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.spacing.s),
                  color: theme.surfaceContainerColorScheme.layer02,
                ),
                padding: EdgeInsetsDirectional.fromSTEB(
                  theme.spacing.m,
                  1.0,
                  theme.spacing.s,
                  1.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.label,
                        style: theme.textStyle.body.standard(
                          color: theme.textColorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.cancel,
                      size: 16,
                      color: theme.iconColorScheme.tertiary,
                    ),
                  ],
                ),
              );
            }),
            TextField(
              enabled: !isDisabled,
              decoration: InputDecoration(
                hintText: items.isEmpty ? emptyLabel ?? "(optional)" : null,
                hintStyle: theme.textStyle.body.standard(
                  color: theme.textColorScheme.tertiary,
                ),
                border: InputBorder.none,
                constraints: const BoxConstraints(maxWidth: 120),
                isCollapsed: true,
                isDense: true,
              ),
              style: theme.textStyle.body.standard(
                color: isDisabled
                    ? theme.textColorScheme.tertiary
                    : theme.textColorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      items.isEmpty ? emptyLabel ?? "(optional)" : items.first.label,
      style: theme.textStyle.body.standard(
        color: isDisabled || items.isEmpty
            ? theme.textColorScheme.tertiary
            : theme.textColorScheme.primary,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

class _DropdownPopoverContents<T extends AFDropDownMenuMixin>
    extends StatelessWidget {
  const _DropdownPopoverContents({
    super.key,
    required this.items,
    this.selectedItems = const [],
    this.onSelected,
    this.isMultiselect = false,
    this.selectedIcon,
    this.itemBuilder,
  });

  final List<T> items;
  final List<T> selectedItems;
  final ValueChanged<T>? onSelected;
  final bool isMultiselect;
  final Widget? selectedIcon;
  final DropDownMenuItemBuilder<T>? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return FocusScope(
      autofocus: true,
      child: ListView.builder(
        itemCount: items.length,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.all(theme.spacing.m),
        shrinkWrap: true,
        itemBuilder: (context, index) =>
            itemBuilder?.call(
              context,
              items[index],
              selectedItems.contains(items[index]),
              onSelected,
            ) ??
            _itemBuilder(context, index),
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final theme = AppFlowyTheme.of(context);
    final item = items[index];

    return AFBaseButton(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.m,
      ),
      borderRadius: theme.borderRadius.m,
      borderColor: (context, isHovering, disabled, isFocused) {
        return Colors.transparent;
      },
      showFocusRing: false,
      builder: (context, _, __) {
        return Row(
          spacing: theme.spacing.m,
          children: [
            Expanded(
              child: Text(
                item.label,
                style: theme.textStyle.body
                    .standard(color: theme.textColorScheme.primary)
                    .copyWith(overflow: TextOverflow.ellipsis),
              ),
            ),
            if (selectedItems.contains(item) && isMultiselect)
              selectedIcon ??
                  Icon(
                    Icons.check,
                    color: theme.fillColorScheme.themeThick,
                    size: 20.0,
                  ),
          ],
        );
      },
      backgroundColor: (context, isHovering, _) {
        if (selectedItems.contains(item) && !isMultiselect) {
          return theme.fillColorScheme.themeSelect;
        }
        if (isHovering) {
          return theme.fillColorScheme.contentHover;
        }
        return Colors.transparent;
      },
      onTap: () {
        onSelected?.call(item);
      },
    );
  }
}
