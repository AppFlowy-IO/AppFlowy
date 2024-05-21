import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/rename_view/rename_view_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/rename_view_dialog.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/rename_view_popover.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ViewItemOnSelected = void Function(BuildContext context, ViewPB view);
typedef ViewItemLeftIconBuilder = Widget Function(
  BuildContext context,
  ViewPB view,
);
typedef ViewItemRightIconsBuilder = List<Widget> Function(
  BuildContext context,
  ViewPB view,
);

class ViewItem extends StatelessWidget {
  const ViewItem({
    super.key,
    required this.view,
    this.parentView,
    required this.spaceType,
    required this.level,
    this.leftPadding = 10,
    required this.onSelected,
    this.onTertiarySelected,
    this.isFirstChild = false,
    this.isDraggable = true,
    required this.isFeedback,
    this.height = HomeSpaceViewSizes.viewHeight,
    this.isHoverEnabled = true,
    this.isPlaceholder = false,
    this.isHovered,
    this.shouldRenderChildren = true,
    this.leftIconBuilder,
    this.rightIconsBuilder,
  });

  final ViewPB view;
  final ViewPB? parentView;

  final FolderSpaceType spaceType;

  // indicate the level of the view item
  // used to calculate the left padding
  final int level;

  // the left padding of the view item for each level
  // the left padding of the each level = level * leftPadding
  final double leftPadding;

  // Selected by normal conventions
  final ViewItemOnSelected onSelected;

  // Selected by middle mouse button
  final ViewItemOnSelected? onTertiarySelected;

  // used for indicating the first child of the parent view, so that we can
  // add top border to the first child
  final bool isFirstChild;

  // it should be false when it's rendered as feedback widget inside DraggableItem
  final bool isDraggable;

  // identify if the view item is rendered as feedback widget inside DraggableItem
  final bool isFeedback;

  final double height;

  final bool isHoverEnabled;

  // all the view movement depends on the [ViewItem] widget, so we have to add a
  // placeholder widget to receive the drop event when moving view across sections.
  final bool isPlaceholder;

  // used for control the expand/collapse icon
  final ValueNotifier<bool>? isHovered;

  // render the child views of the view
  final bool shouldRenderChildren;

  // custom the left icon widget, if it's null, the default expand/collapse icon will be used
  final ViewItemLeftIconBuilder? leftIconBuilder;
  // custom the right icon widget, if it's null, the default ... and + button will be used
  final ViewItemRightIconsBuilder? rightIconsBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewBloc(view: view)..add(const ViewEvent.initial()),
      child: BlocConsumer<ViewBloc, ViewState>(
        listenWhen: (p, c) =>
            c.lastCreatedView != null &&
            p.lastCreatedView?.id != c.lastCreatedView!.id,
        listener: (context, state) =>
            context.read<TabsBloc>().openPlugin(state.lastCreatedView!),
        builder: (context, state) {
          return InnerViewItem(
            view: state.view,
            parentView: parentView,
            childViews: state.view.childViews,
            spaceType: spaceType,
            level: level,
            leftPadding: leftPadding,
            showActions: state.isEditing,
            isExpanded: state.isExpanded,
            onSelected: onSelected,
            onTertiarySelected: onTertiarySelected,
            isFirstChild: isFirstChild,
            isDraggable: isDraggable,
            isFeedback: isFeedback,
            height: height,
            isHoverEnabled: isHoverEnabled,
            isPlaceholder: isPlaceholder,
            isHovered: isHovered,
            shouldRenderChildren: shouldRenderChildren,
            leftIconBuilder: leftIconBuilder,
            rightIconsBuilder: rightIconsBuilder,
          );
        },
      ),
    );
  }
}

bool _isDragging = false;

class InnerViewItem extends StatelessWidget {
  const InnerViewItem({
    super.key,
    required this.view,
    required this.parentView,
    required this.childViews,
    required this.spaceType,
    this.isDraggable = true,
    this.isExpanded = true,
    required this.level,
    required this.leftPadding,
    required this.showActions,
    required this.onSelected,
    this.onTertiarySelected,
    this.isFirstChild = false,
    required this.isFeedback,
    required this.height,
    this.isHoverEnabled = true,
    this.isPlaceholder = false,
    this.isHovered,
    this.shouldRenderChildren = true,
    required this.leftIconBuilder,
    required this.rightIconsBuilder,
  });

  final ViewPB view;
  final ViewPB? parentView;
  final List<ViewPB> childViews;
  final FolderSpaceType spaceType;

  final bool isDraggable;
  final bool isExpanded;
  final bool isFirstChild;
  // identify if the view item is rendered as feedback widget inside DraggableItem
  final bool isFeedback;

  final int level;
  final double leftPadding;

  final bool showActions;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;
  final double height;

  final bool isHoverEnabled;
  final bool isPlaceholder;
  final ValueNotifier<bool>? isHovered;
  final bool shouldRenderChildren;
  final ViewItemLeftIconBuilder? leftIconBuilder;
  final ViewItemRightIconsBuilder? rightIconsBuilder;

  @override
  Widget build(BuildContext context) {
    Widget child = SingleInnerViewItem(
      view: view,
      parentView: parentView,
      level: level,
      showActions: showActions,
      spaceType: spaceType,
      onSelected: onSelected,
      onTertiarySelected: onTertiarySelected,
      isExpanded: isExpanded,
      isDraggable: isDraggable,
      leftPadding: leftPadding,
      isFeedback: isFeedback,
      height: height,
      isPlaceholder: isPlaceholder,
      isHovered: isHovered,
      leftIconBuilder: leftIconBuilder,
      rightIconsBuilder: rightIconsBuilder,
    );

    // if the view is expanded and has child views, render its child views
    if (isExpanded && shouldRenderChildren) {
      if (childViews.isNotEmpty) {
        final children = childViews.map((childView) {
          return ViewItem(
            key: ValueKey('${spaceType.name} ${childView.id}'),
            parentView: view,
            spaceType: spaceType,
            isFirstChild: childView.id == childViews.first.id,
            view: childView,
            level: level + 1,
            onSelected: onSelected,
            onTertiarySelected: onTertiarySelected,
            isDraggable: isDraggable,
            leftPadding: leftPadding,
            isFeedback: isFeedback,
            isPlaceholder: isPlaceholder,
            isHovered: isHovered,
            leftIconBuilder: leftIconBuilder,
            rightIconsBuilder: rightIconsBuilder,
          );
        }).toList();

        child = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            ...children,
          ],
        );
      } else {
        child = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            Container(
              height: height,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: (level + 2) * leftPadding),
                child: FlowyText.regular(
                  LocaleKeys.noPagesInside.tr(),
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ],
        );
      }
    }

    // wrap the child with DraggableItem if isDraggable is true
    if ((isDraggable || isPlaceholder) &&
        !isReferencedDatabaseView(view, parentView)) {
      child = DraggableViewItem(
        isFirstChild: isFirstChild,
        view: view,
        onDragging: (isDragging) {
          _isDragging = isDragging;
        },
        onMove: isPlaceholder
            ? (from, to) => _moveViewCrossSection(context, from, to)
            : null,
        feedback: (context) {
          return Container(
            width: 250,
            decoration: BoxDecoration(
              color: Brightness.light == Theme.of(context).brightness
                  ? Colors.white
                  : Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ViewItem(
              view: view,
              parentView: parentView,
              spaceType: spaceType,
              level: level,
              onSelected: onSelected,
              onTertiarySelected: onTertiarySelected,
              isDraggable: false,
              leftPadding: leftPadding,
              isFeedback: true,
              leftIconBuilder: leftIconBuilder,
              rightIconsBuilder: rightIconsBuilder,
            ),
          );
        },
        child: child,
      );
    } else {
      // keep the same height of the DraggableItem
      child = Padding(
        padding: const EdgeInsets.only(top: kDraggableViewItemDividerHeight),
        child: child,
      );
    }

    return child;
  }

  void _moveViewCrossSection(
    BuildContext context,
    ViewPB from,
    ViewPB to,
  ) {
    if (isReferencedDatabaseView(view, parentView)) {
      return;
    }
    final fromSection = spaceType == FolderSpaceType.public
        ? ViewSectionPB.Private
        : ViewSectionPB.Public;
    final toSection = spaceType == FolderSpaceType.public
        ? ViewSectionPB.Public
        : ViewSectionPB.Private;
    context.read<ViewBloc>().add(
          ViewEvent.move(
            from,
            to.parentViewId,
            null,
            fromSection,
            toSection,
          ),
        );
    context.read<ViewBloc>().add(
          ViewEvent.updateViewVisibility(
            from,
            spaceType == FolderSpaceType.public,
          ),
        );
  }
}

class SingleInnerViewItem extends StatefulWidget {
  const SingleInnerViewItem({
    super.key,
    required this.view,
    required this.parentView,
    required this.isExpanded,
    required this.level,
    required this.leftPadding,
    this.isDraggable = true,
    required this.spaceType,
    required this.showActions,
    required this.onSelected,
    this.onTertiarySelected,
    required this.isFeedback,
    required this.height,
    this.isHoverEnabled = true,
    this.isPlaceholder = false,
    this.isHovered,
    required this.leftIconBuilder,
    required this.rightIconsBuilder,
  });

  final ViewPB view;
  final ViewPB? parentView;
  final bool isExpanded;
  // identify if the view item is rendered as feedback widget inside DraggableItem
  final bool isFeedback;

  final int level;
  final double leftPadding;

  final bool isDraggable;
  final bool showActions;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;
  final FolderSpaceType spaceType;
  final double height;

  final bool isHoverEnabled;
  final bool isPlaceholder;
  final ValueNotifier<bool>? isHovered;
  final ViewItemLeftIconBuilder? leftIconBuilder;
  final ViewItemRightIconsBuilder? rightIconsBuilder;

  @override
  State<SingleInnerViewItem> createState() => _SingleInnerViewItemState();
}

class _SingleInnerViewItemState extends State<SingleInnerViewItem> {
  final controller = PopoverController();
  bool isIconPickerOpened = false;

  @override
  Widget build(BuildContext context) {
    final isSelected =
        getIt<MenuSharedState>().latestOpenView?.id == widget.view.id;

    if (widget.isPlaceholder) {
      return const SizedBox(
        height: 4,
        width: double.infinity,
      );
    }

    if (widget.isFeedback || !widget.isHoverEnabled) {
      return _buildViewItem(
        false,
        !widget.isHoverEnabled ? isSelected : false,
      );
    }

    return FlowyHover(
      style: HoverStyle(
        hoverColor: Theme.of(context).colorScheme.secondary,
      ),
      resetHoverOnRebuild: widget.showActions || !isIconPickerOpened,
      buildWhenOnHover: () =>
          !widget.showActions && !_isDragging && !isIconPickerOpened,
      builder: (_, onHover) => _buildViewItem(onHover, isSelected),
      isSelected: () => widget.showActions || isSelected,
    );
  }

  Widget _buildViewItem(bool onHover, [bool isSelected = false]) {
    final children = [
      // expand icon or placeholder
      widget.leftIconBuilder?.call(context, widget.view) ?? _buildLeftIcon(),
      // icon
      _buildViewIconButton(),
      const HSpace(6),
      // title
      Expanded(
        child: SizedBox(
          height: 18.0,
          child: FlowyText.regular(
            widget.view.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    // hover action
    if (widget.showActions || onHover) {
      if (widget.rightIconsBuilder != null) {
        children.addAll(widget.rightIconsBuilder!(context, widget.view));
      } else {
        // ··· more action button
        children.add(_buildViewMoreActionButton(context));
        children.add(const HSpace(8.0));
        // only support add button for document layout
        if (widget.view.layout == ViewLayoutPB.Document) {
          // + button
          children.add(_buildViewAddButton(context));
        }
        children.add(const HSpace(4.0));
      }
    }

    final child = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => widget.onSelected(context, widget.view),
      onTertiaryTapDown: (_) =>
          widget.onTertiarySelected?.call(context, widget.view),
      child: SizedBox(
        height: widget.height,
        child: Padding(
          padding: EdgeInsets.only(left: widget.level * widget.leftPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );

    if (isSelected) {
      final popoverController = getIt<RenameViewBloc>().state.controller;
      return AppFlowyPopover(
        controller: popoverController,
        triggerActions: PopoverTriggerFlags.none,
        offset: const Offset(0, 5),
        direction: PopoverDirection.bottomWithLeftAligned,
        popupBuilder: (_) => RenameViewPopover(
          viewId: widget.view.id,
          name: widget.view.name,
          emoji: widget.view.icon.value,
          popoverController: popoverController,
          showIconChanger: false,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildViewIconButton() {
    final icon = SizedBox.square(
      dimension: 16.0,
      child: widget.view.icon.value.isNotEmpty
          ? FlowyText.emoji(
              widget.view.icon.value,
              fontSize: 16.0,
            )
          : widget.view.defaultIcon(),
    );

    return AppFlowyPopover(
      offset: const Offset(20, 0),
      controller: controller,
      direction: PopoverDirection.rightWithCenterAligned,
      constraints: BoxConstraints.loose(const Size(364, 356)),
      onClose: () => setState(() => isIconPickerOpened = false),
      child: GestureDetector(
        // prevent the tap event from being passed to the parent widget
        onTap: () {},
        child: FlowyTooltip(
          message: LocaleKeys.document_plugins_cover_changeIcon.tr(),
          child: icon,
        ),
      ),
      popupBuilder: (context) {
        isIconPickerOpened = true;
        return FlowyIconPicker(
          onSelected: (result) {
            ViewBackendService.updateViewIcon(
              viewId: widget.view.id,
              viewIcon: result.emoji,
              iconType: result.type.toProto(),
            );
            controller.close();
          },
        );
      },
    );
  }

  // > button or · button
  // show > if the view is expandable.
  // show · if the view can't contain child views.
  Widget _buildLeftIcon() {
    if (isReferencedDatabaseView(widget.view, widget.parentView)) {
      return const _DotIconWidget();
    }

    final child = GestureDetector(
      child: FlowySvg(
        widget.isExpanded
            ? FlowySvgs.view_item_expand_s
            : FlowySvgs.view_item_unexpand_s,
        size: const Size.square(16.0),
      ),
      onTap: () => context
          .read<ViewBloc>()
          .add(ViewEvent.setIsExpanded(!widget.isExpanded)),
    );

    if (widget.isHovered != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: widget.isHovered!,
        builder: (_, isHovered, child) {
          return Opacity(opacity: isHovered ? 1.0 : 0.0, child: child);
        },
        child: child,
      );
    }

    return child;
  }

  // + button
  Widget _buildViewAddButton(BuildContext context) {
    final viewBloc = context.read<ViewBloc>();
    return FlowyTooltip(
      message: LocaleKeys.menuAppHeader_addPageTooltip.tr(),
      child: ViewAddButton(
        parentViewId: widget.view.id,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onSelected: (
          pluginBuilder,
          name,
          initialDataBytes,
          openAfterCreated,
          createNewView,
        ) {
          if (createNewView) {
            createViewAndShowRenameDialogIfNeeded(
              context,
              _convertLayoutToHintText(pluginBuilder.layoutType!),
              (viewName, _) {
                if (viewName.isNotEmpty) {
                  viewBloc.add(
                    ViewEvent.createView(
                      viewName,
                      pluginBuilder.layoutType!,
                      openAfterCreated: openAfterCreated,
                      section: widget.spaceType.toViewSectionPB,
                    ),
                  );
                }
              },
            );
          }
          viewBloc.add(
            const ViewEvent.setIsExpanded(true),
          );
        },
      ),
    );
  }

  // ··· more action button
  Widget _buildViewMoreActionButton(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.menuAppHeader_moreButtonToolTip.tr(),
      child: ViewMoreActionButton(
        view: widget.view,
        spaceType: widget.spaceType,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onAction: (action, data) {
          switch (action) {
            case ViewMoreActionType.favorite:
            case ViewMoreActionType.unFavorite:
              context
                  .read<FavoriteBloc>()
                  .add(FavoriteEvent.toggle(widget.view));
              break;
            case ViewMoreActionType.rename:
              NavigatorTextFieldDialog(
                title: LocaleKeys.disclosureAction_rename.tr(),
                autoSelectAllText: true,
                value: widget.view.name,
                maxLength: 256,
                onConfirm: (newValue, _) {
                  context.read<ViewBloc>().add(ViewEvent.rename(newValue));
                },
              ).show(context);
              break;
            case ViewMoreActionType.delete:
              context.read<ViewBloc>().add(const ViewEvent.delete());
              break;
            case ViewMoreActionType.duplicate:
              context.read<ViewBloc>().add(const ViewEvent.duplicate());
              break;
            case ViewMoreActionType.openInNewTab:
              context.read<TabsBloc>().openTab(widget.view);
              break;
            case ViewMoreActionType.collapseAllPages:
              context.read<ViewBloc>().add(const ViewEvent.collapseAllPages());
              break;
            case ViewMoreActionType.changeIcon:
              if (data is! EmojiPickerResult) {
                return;
              }
              final result = data;
              ViewBackendService.updateViewIcon(
                viewId: widget.view.id,
                viewIcon: result.emoji,
                iconType: result.type.toProto(),
              );
              break;
            default:
              throw UnsupportedError('$action is not supported');
          }
        },
      ),
    );
  }

  String _convertLayoutToHintText(ViewLayoutPB layout) {
    switch (layout) {
      case ViewLayoutPB.Document:
        return LocaleKeys.newDocumentText.tr();
      case ViewLayoutPB.Grid:
        return LocaleKeys.newGridText.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.newBoardText.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.newCalendarText.tr();
    }
    return LocaleKeys.newPageText.tr();
  }
}

class _DotIconWidget extends StatelessWidget {
  const _DotIconWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// workaround: we should use view.isEndPoint or something to check if the view can contain child views. But currently, we don't have that field.
bool isReferencedDatabaseView(ViewPB view, ViewPB? parentView) {
  if (parentView == null) {
    return false;
  }
  return view.layout.isDatabaseView && parentView.layout.isDatabaseView;
}
