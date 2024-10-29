import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/rename_view/rename_view_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
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
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/gestures.dart';
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

enum IgnoreViewType { none, hide, disable }

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
    this.isHoverEnabled = false,
    this.isPlaceholder = false,
    this.isHovered,
    this.shouldRenderChildren = true,
    this.leftIconBuilder,
    this.rightIconsBuilder,
    this.shouldLoadChildViews = true,
    this.isExpandedNotifier,
    this.extendBuilder,
    this.disableSelectedStatus,
    this.shouldIgnoreView,
    this.enableRightClickContext = false,
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

  final bool shouldLoadChildViews;
  final PropertyValueNotifier<bool>? isExpandedNotifier;

  final List<Widget> Function(ViewPB view)? extendBuilder;

  // disable the selected status of the view item
  final bool? disableSelectedStatus;

  // ignore the views when rendering the child views
  final IgnoreViewType Function(ViewPB view)? shouldIgnoreView;

  /// Whether to add right-click to show the view action context menu
  ///
  final bool enableRightClickContext;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ViewBloc(view: view, shouldLoadChildViews: shouldLoadChildViews)
            ..add(const ViewEvent.initial()),
      child: BlocConsumer<ViewBloc, ViewState>(
        listenWhen: (p, c) =>
            c.lastCreatedView != null &&
            p.lastCreatedView?.id != c.lastCreatedView!.id,
        listener: (context, state) =>
            context.read<TabsBloc>().openPlugin(state.lastCreatedView!),
        builder: (context, state) {
          // filter the child views that should be ignored
          List<ViewPB> childViews = state.view.childViews;
          if (shouldIgnoreView != null) {
            childViews = childViews
                .where((v) => shouldIgnoreView!(v) != IgnoreViewType.hide)
                .toList();
          }

          final Widget child = InnerViewItem(
            view: state.view,
            parentView: parentView,
            childViews: childViews,
            spaceType: spaceType,
            level: level,
            leftPadding: leftPadding,
            showActions: state.isEditing,
            enableRightClickContext: enableRightClickContext,
            isExpanded: state.isExpanded,
            disableSelectedStatus: disableSelectedStatus,
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
            isExpandedNotifier: isExpandedNotifier,
            extendBuilder: extendBuilder,
            shouldIgnoreView: shouldIgnoreView,
          );

          if (shouldIgnoreView?.call(view) == IgnoreViewType.disable) {
            return Opacity(
              opacity: 0.5,
              child: FlowyTooltip(
                message: LocaleKeys.space_cannotMovePageToDatabase.tr(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.forbidden,
                  child: IgnorePointer(child: child),
                ),
              ),
            );
          }

          return child;
        },
      ),
    );
  }
}

// TODO: We shouldn't have local global variables
bool _isDragging = false;

class InnerViewItem extends StatefulWidget {
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
    this.enableRightClickContext = false,
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
    this.isExpandedNotifier,
    required this.extendBuilder,
    this.disableSelectedStatus,
    required this.shouldIgnoreView,
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
  final bool enableRightClickContext;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;
  final double height;

  final bool isHoverEnabled;
  final bool isPlaceholder;
  final bool? disableSelectedStatus;
  final ValueNotifier<bool>? isHovered;
  final bool shouldRenderChildren;
  final ViewItemLeftIconBuilder? leftIconBuilder;
  final ViewItemRightIconsBuilder? rightIconsBuilder;

  final PropertyValueNotifier<bool>? isExpandedNotifier;
  final List<Widget> Function(ViewPB view)? extendBuilder;
  final IgnoreViewType Function(ViewPB view)? shouldIgnoreView;

  @override
  State<InnerViewItem> createState() => _InnerViewItemState();
}

class _InnerViewItemState extends State<InnerViewItem> {
  @override
  void initState() {
    super.initState();
    widget.isExpandedNotifier?.addListener(_collapseAllPages);
  }

  @override
  void dispose() {
    widget.isExpandedNotifier?.removeListener(_collapseAllPages);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ValueListenableBuilder(
      valueListenable: getIt<MenuSharedState>().notifier,
      builder: (context, value, _) {
        final isSelected = value?.id == widget.view.id;
        return SingleInnerViewItem(
          view: widget.view,
          parentView: widget.parentView,
          level: widget.level,
          showActions: widget.showActions,
          enableRightClickContext: widget.enableRightClickContext,
          spaceType: widget.spaceType,
          onSelected: widget.onSelected,
          onTertiarySelected: widget.onTertiarySelected,
          isExpanded: widget.isExpanded,
          isDraggable: widget.isDraggable,
          leftPadding: widget.leftPadding,
          isFeedback: widget.isFeedback,
          height: widget.height,
          isPlaceholder: widget.isPlaceholder,
          isHovered: widget.isHovered,
          leftIconBuilder: widget.leftIconBuilder,
          rightIconsBuilder: widget.rightIconsBuilder,
          extendBuilder: widget.extendBuilder,
          disableSelectedStatus: widget.disableSelectedStatus,
          shouldIgnoreView: widget.shouldIgnoreView,
          isSelected: isSelected,
        );
      },
    );

    // if the view is expanded and has child views, render its child views
    if (widget.isExpanded &&
        widget.shouldRenderChildren &&
        widget.childViews.isNotEmpty) {
      final children = widget.childViews.map((childView) {
        return ViewItem(
          key: ValueKey('${widget.spaceType.name} ${childView.id}'),
          parentView: widget.view,
          spaceType: widget.spaceType,
          isFirstChild: childView.id == widget.childViews.first.id,
          view: childView,
          level: widget.level + 1,
          enableRightClickContext: widget.enableRightClickContext,
          onSelected: widget.onSelected,
          onTertiarySelected: widget.onTertiarySelected,
          isDraggable: widget.isDraggable,
          disableSelectedStatus: widget.disableSelectedStatus,
          leftPadding: widget.leftPadding,
          isFeedback: widget.isFeedback,
          isPlaceholder: widget.isPlaceholder,
          isHovered: widget.isHovered,
          leftIconBuilder: widget.leftIconBuilder,
          rightIconsBuilder: widget.rightIconsBuilder,
          extendBuilder: widget.extendBuilder,
          shouldIgnoreView: widget.shouldIgnoreView,
        );
      }).toList();

      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [child, ...children],
      );
    }

    // wrap the child with DraggableItem if isDraggable is true
    if ((widget.isDraggable || widget.isPlaceholder) &&
        !isReferencedDatabaseView(widget.view, widget.parentView)) {
      child = DraggableViewItem(
        isFirstChild: widget.isFirstChild,
        view: widget.view,
        onDragging: (isDragging) => _isDragging = isDragging,
        onMove: widget.isPlaceholder
            ? (from, to) => moveViewCrossSpace(
                  context,
                  null,
                  widget.view,
                  widget.parentView,
                  widget.spaceType,
                  from,
                  to.parentViewId,
                )
            : null,
        feedback: (context) => Container(
          width: 250,
          decoration: BoxDecoration(
            color: Brightness.light == Theme.of(context).brightness
                ? Colors.white
                : Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ViewItem(
            view: widget.view,
            parentView: widget.parentView,
            spaceType: widget.spaceType,
            level: widget.level,
            onSelected: widget.onSelected,
            onTertiarySelected: widget.onTertiarySelected,
            isDraggable: false,
            leftPadding: widget.leftPadding,
            isFeedback: true,
            enableRightClickContext: widget.enableRightClickContext,
            leftIconBuilder: widget.leftIconBuilder,
            rightIconsBuilder: widget.rightIconsBuilder,
            extendBuilder: widget.extendBuilder,
            shouldIgnoreView: widget.shouldIgnoreView,
          ),
        ),
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

  void _collapseAllPages() {
    if (widget.isExpandedNotifier?.value == true) {
      context.read<ViewBloc>().add(const ViewEvent.collapseAllPages());
    }
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
    this.enableRightClickContext = false,
    required this.onSelected,
    this.onTertiarySelected,
    required this.isFeedback,
    required this.height,
    this.isHoverEnabled = true,
    this.isPlaceholder = false,
    this.isHovered,
    required this.leftIconBuilder,
    required this.rightIconsBuilder,
    required this.extendBuilder,
    required this.disableSelectedStatus,
    required this.shouldIgnoreView,
    required this.isSelected,
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
  final bool enableRightClickContext;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;
  final FolderSpaceType spaceType;
  final double height;

  final bool isHoverEnabled;
  final bool isPlaceholder;
  final bool? disableSelectedStatus;
  final ValueNotifier<bool>? isHovered;
  final ViewItemLeftIconBuilder? leftIconBuilder;
  final ViewItemRightIconsBuilder? rightIconsBuilder;

  final List<Widget> Function(ViewPB view)? extendBuilder;
  final IgnoreViewType Function(ViewPB view)? shouldIgnoreView;
  final bool isSelected;

  @override
  State<SingleInnerViewItem> createState() => _SingleInnerViewItemState();
}

class _SingleInnerViewItemState extends State<SingleInnerViewItem> {
  final controller = PopoverController();
  final viewMoreActionController = PopoverController();

  bool isIconPickerOpened = false;

  @override
  Widget build(BuildContext context) {
    bool isSelected = widget.isSelected;

    if (widget.disableSelectedStatus == true) {
      isSelected = false;
    }

    if (widget.isPlaceholder) {
      return const SizedBox(height: 4, width: double.infinity);
    }

    if (widget.isFeedback || !widget.isHoverEnabled) {
      return _buildViewItem(
        false,
        !widget.isHoverEnabled ? isSelected : false,
      );
    }

    return FlowyHover(
      style: HoverStyle(hoverColor: Theme.of(context).colorScheme.secondary),
      resetHoverOnRebuild: widget.showActions || !isIconPickerOpened,
      buildWhenOnHover: () =>
          !widget.showActions && !_isDragging && !isIconPickerOpened,
      isSelected: () => widget.showActions || isSelected,
      builder: (_, onHover) => _buildViewItem(onHover, isSelected),
    );
  }

  Widget _buildViewItem(bool onHover, [bool isSelected = false]) {
    final name = FlowyText.regular(
      widget.view.nameOrDefault,
      overflow: TextOverflow.ellipsis,
      fontSize: 14.0,
      figmaLineHeight: 18.0,
    );
    final children = [
      const HSpace(2),
      // expand icon or placeholder
      widget.leftIconBuilder?.call(context, widget.view) ?? _buildLeftIcon(),
      const HSpace(2),
      // icon
      _buildViewIconButton(),
      const HSpace(6),
      // title
      Expanded(
        child: widget.extendBuilder != null
            ? Row(
                children: [
                  Flexible(child: name),
                  ...widget.extendBuilder!(widget.view),
                ],
              )
            : name,
      ),
    ];

    // hover action
    if (widget.showActions || onHover) {
      if (widget.rightIconsBuilder != null) {
        children.addAll(widget.rightIconsBuilder!(context, widget.view));
      } else {
        // ··· more action button
        children.add(
          _buildViewMoreActionButton(
            context,
            viewMoreActionController,
            (_) => FlowyTooltip(
              message: LocaleKeys.menuAppHeader_moreButtonToolTip.tr(),
              child: FlowyIconButton(
                width: 24,
                icon: const FlowySvg(FlowySvgs.workspace_three_dots_s),
                onPressed: viewMoreActionController.show,
              ),
            ),
          ),
        );
        // only support add button for document layout
        if (widget.view.layout == ViewLayoutPB.Document) {
          // + button
          children.add(const HSpace(8.0));
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
          child: Listener(
            onPointerDown: (event) {
              if (event.buttons == kSecondaryMouseButton &&
                  widget.enableRightClickContext) {
                viewMoreActionController.showAt(event.position);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Row(children: children),
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
    final icon = widget.view.icon.value.isNotEmpty
        ? FlowyText.emoji(
            widget.view.icon.value,
            fontSize: 16.0,
            figmaLineHeight: 21.0,
          )
        : Opacity(opacity: 0.6, child: widget.view.defaultIcon());

    return AppFlowyPopover(
      offset: const Offset(20, 0),
      controller: controller,
      direction: PopoverDirection.rightWithCenterAligned,
      constraints: BoxConstraints.loose(const Size(364, 356)),
      margin: const EdgeInsets.all(0),
      onClose: () => setState(() => isIconPickerOpened = false),
      child: GestureDetector(
        // prevent the tap event from being passed to the parent widget
        onTap: () {},
        child: FlowyTooltip(
          message: LocaleKeys.document_plugins_cover_changeIcon.tr(),
          child: SizedBox(width: 16.0, child: icon),
        ),
      ),
      popupBuilder: (context) {
        isIconPickerOpened = true;
        return FlowyIconEmojiPicker(
          onSelectedEmoji: (result) {
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
    return ViewItemDefaultLeftIcon(
      view: widget.view,
      parentView: widget.parentView,
      isExpanded: widget.isExpanded,
      leftPadding: widget.leftPadding,
      isHovered: widget.isHovered,
    );
  }

  // + button
  Widget _buildViewAddButton(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.menuAppHeader_addPageTooltip.tr(),
      child: ViewAddButton(
        parentViewId: widget.view.id,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onSelected: _onSelected,
      ),
    );
  }

  void _onSelected(
    PluginBuilder pluginBuilder,
    String? name,
    List<int>? initialDataBytes,
    bool openAfterCreated,
    bool createNewView,
  ) {
    final viewBloc = context.read<ViewBloc>();

    if (createNewView) {
      createViewAndShowRenameDialogIfNeeded(
        context,
        _convertLayoutToHintText(pluginBuilder.layoutType!),
        (viewName, _) {
          // the name of new document should be empty
          if (pluginBuilder.layoutType == ViewLayoutPB.Document) {
            viewName = '';
          }
          viewBloc.add(
            ViewEvent.createView(
              viewName,
              pluginBuilder.layoutType!,
              openAfterCreated: openAfterCreated,
              section: widget.spaceType.toViewSectionPB,
            ),
          );
        },
      );
    }

    viewBloc.add(const ViewEvent.setIsExpanded(true));
  }

  // ··· more action button
  Widget _buildViewMoreActionButton(
    BuildContext context,
    PopoverController controller,
    Widget Function(PopoverController) buildChild,
  ) {
    return BlocProvider(
      create: (context) => SpaceBloc(
        userProfile: context.read<SpaceBloc>().userProfile,
        workspaceId: context.read<SpaceBloc>().workspaceId,
      )..add(const SpaceEvent.initial(openFirstPage: false)),
      child: ViewMoreActionPopover(
        view: widget.view,
        controller: controller,
        isExpanded: widget.isExpanded,
        spaceType: widget.spaceType,
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        buildChild: buildChild,
        onAction: (action, data) async {
          switch (action) {
            case ViewMoreActionType.favorite:
            case ViewMoreActionType.unFavorite:
              context
                  .read<FavoriteBloc>()
                  .add(FavoriteEvent.toggle(widget.view));
              break;
            case ViewMoreActionType.rename:
              unawaited(
                NavigatorTextFieldDialog(
                  title: LocaleKeys.disclosureAction_rename.tr(),
                  autoSelectAllText: true,
                  value: widget.view.name,
                  maxLength: 256,
                  onConfirm: (newValue, _) {
                    context.read<ViewBloc>().add(ViewEvent.rename(newValue));
                  },
                ).show(context),
              );
              break;
            case ViewMoreActionType.delete:
              // get if current page contains published child views
              final (containPublishedPage, _) =
                  await ViewBackendService.containPublishedPage(widget.view);
              if (containPublishedPage && context.mounted) {
                await showConfirmDeletionDialog(
                  context: context,
                  name: widget.view.name,
                  description: LocaleKeys.publish_containsPublishedPage.tr(),
                  onConfirm: () =>
                      context.read<ViewBloc>().add(const ViewEvent.delete()),
                );
              } else if (context.mounted) {
                context.read<ViewBloc>().add(const ViewEvent.delete());
              }
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
              await ViewBackendService.updateViewIcon(
                viewId: widget.view.id,
                viewIcon: result.emoji,
                iconType: result.type.toProto(),
              );
              break;
            case ViewMoreActionType.moveTo:
              final value = data;
              if (value is! (ViewPB, ViewPB)) {
                return;
              }
              final space = value.$1;
              final target = value.$2;
              moveViewCrossSpace(
                context,
                space,
                widget.view,
                widget.parentView,
                widget.spaceType,
                widget.view,
                target.id,
              );
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
      case ViewLayoutPB.Chat:
        return LocaleKeys.chat_newChat.tr();
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

void moveViewCrossSpace(
  BuildContext context,
  ViewPB? toSpace,
  ViewPB view,
  ViewPB? parentView,
  FolderSpaceType spaceType,
  ViewPB from,
  String toId,
) {
  if (isReferencedDatabaseView(view, parentView)) {
    return;
  }

  if (from.id == toId) {
    return;
  }

  final currentSpace = context.read<SpaceBloc>().state.currentSpace;
  if (currentSpace != null &&
      toSpace != null &&
      currentSpace.id != toSpace.id) {
    Log.info(
      'Move view(${from.name}) to another space(${toSpace.name}), unpublish the view',
    );
    context.read<ViewBloc>().add(const ViewEvent.unpublish(sync: false));
  }

  context.read<ViewBloc>().add(ViewEvent.move(from, toId, null, null, null));
}

class ViewItemDefaultLeftIcon extends StatelessWidget {
  const ViewItemDefaultLeftIcon({
    super.key,
    required this.view,
    required this.parentView,
    required this.isExpanded,
    required this.leftPadding,
    required this.isHovered,
  });

  final ViewPB view;
  final ViewPB? parentView;
  final bool isExpanded;
  final double leftPadding;
  final ValueNotifier<bool>? isHovered;

  @override
  Widget build(BuildContext context) {
    if (isReferencedDatabaseView(view, parentView)) {
      return const _DotIconWidget();
    }

    if (context.read<ViewBloc>().state.view.childViews.isEmpty) {
      return HSpace(leftPadding);
    }

    final child = FlowyHover(
      child: GestureDetector(
        child: FlowySvg(
          isExpanded
              ? FlowySvgs.view_item_expand_s
              : FlowySvgs.view_item_unexpand_s,
          size: const Size.square(16.0),
        ),
        onTap: () =>
            context.read<ViewBloc>().add(ViewEvent.setIsExpanded(!isExpanded)),
      ),
    );

    if (isHovered != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: isHovered!,
        builder: (_, isHovered, child) =>
            Opacity(opacity: isHovered ? 1.0 : 0.0, child: child),
        child: child,
      );
    }

    return child;
  }
}
