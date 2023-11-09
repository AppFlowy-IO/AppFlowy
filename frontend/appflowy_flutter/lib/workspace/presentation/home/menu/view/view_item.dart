import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/panes/panes_bloc/panes_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/rename_view_dialog.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ViewItemOnSelected = void Function(ViewPB);

class ViewItem extends StatelessWidget {
  const ViewItem({
    super.key,
    required this.view,
    required this.categoryType,
    required this.level,
    required this.onSelected,
    required this.isFeedback,
    this.parentView,
    this.leftPadding = 10,
    this.onTertiarySelected,
    this.isFirstChild = false,
    this.isDraggable = true,
  });

  final ViewPB view;
  final FolderCategoryType categoryType;

  /// Indicate the level of the view item
  /// used to calculate the left padding
  final int level;

  // Selected by normal conventions
  final ViewItemOnSelected onSelected;

  /// Identify if the view item is rendered as feedback
  /// widget inside DraggableItem
  final bool isFeedback;

  final ViewPB? parentView;

  /// The left padding of the view item for each level
  /// The left padding of the each level = level * leftPadding
  final double leftPadding;

  /// Selected by middle mouse button
  final ViewItemOnSelected? onTertiarySelected;

  /// Used for indicating the first child of the parent view, so that we can
  /// add top border to the first child
  final bool isFirstChild;

  /// It should be false when it's rendered as feedback widget inside DraggableItem
  final bool isDraggable;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewBloc(view: view)..add(const ViewEvent.initial()),
      child: BlocConsumer<ViewBloc, ViewState>(
        listenWhen: (p, c) =>
            c.lastCreatedView != null &&
            p.lastCreatedView?.id != c.lastCreatedView!.id,
        listener: (context, state) => context.read<PanesBloc>().add(
              OpenPluginInActivePane(plugin: state.lastCreatedView!.plugin()),
            ),
        builder: (context, state) {
          // Don't remove this code. it's related to the backend service.
          view.childViews
            ..clear()
            ..addAll(state.childViews);

          return InnerViewItem(
            view: state.view,
            parentView: parentView,
            childViews: state.childViews,
            categoryType: categoryType,
            level: level,
            leftPadding: leftPadding,
            showActions: state.isEditing,
            isExpanded: state.isExpanded,
            onSelected: onSelected,
            onTertiarySelected: onTertiarySelected,
            isFirstChild: isFirstChild,
            isDraggable: isDraggable,
            isFeedback: isFeedback,
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
    required this.categoryType,
    this.isDraggable = true,
    this.isExpanded = true,
    required this.level,
    required this.leftPadding,
    required this.showActions,
    required this.onSelected,
    this.onTertiarySelected,
    this.isFirstChild = false,
    required this.isFeedback,
  });

  final ViewPB view;
  final ViewPB? parentView;
  final List<ViewPB> childViews;
  final FolderCategoryType categoryType;

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

  @override
  Widget build(BuildContext context) {
    Widget child = SingleInnerViewItem(
      view: view,
      parentView: parentView,
      level: level,
      showActions: showActions,
      categoryType: categoryType,
      onSelected: onSelected,
      onTertiarySelected: onTertiarySelected,
      isExpanded: isExpanded,
      isDraggable: isDraggable,
      leftPadding: leftPadding,
      isFeedback: isFeedback,
    );

    // If the view is expanded and has child views, render its child views
    if (isExpanded && childViews.isNotEmpty) {
      final children = childViews.map((childView) {
        return ViewItem(
          key: ValueKey('${categoryType.name} ${childView.id}'),
          parentView: view,
          categoryType: categoryType,
          isFirstChild: childView.id == childViews.first.id,
          view: childView,
          level: level + 1,
          onSelected: onSelected,
          onTertiarySelected: onTertiarySelected,
          isDraggable: isDraggable,
          leftPadding: leftPadding,
          isFeedback: isFeedback,
        );
      }).toList();

      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          ...children,
        ],
      );
    }

    // Wrap the child with DraggableItem if isDraggable is true
    if (isDraggable && !isReferencedDatabaseView(view, parentView)) {
      child = DraggableViewItem(
        isFirstChild: isFirstChild,
        view: view,
        child: child,
        onDragging: (isDragging) => _isDragging = isDragging,
        feedback: (context) {
          return ViewItem(
            view: view,
            parentView: parentView,
            categoryType: categoryType,
            level: level,
            onSelected: onSelected,
            onTertiarySelected: onTertiarySelected,
            isDraggable: false,
            leftPadding: leftPadding,
            isFeedback: true,
          );
        },
      );
    } else {
      // Keep the same height of the DraggableItem
      child = Padding(padding: const EdgeInsets.only(top: 2.0), child: child);
    }

    return child;
  }
}

class SingleInnerViewItem extends StatefulWidget {
  const SingleInnerViewItem({
    super.key,
    required this.view,
    required this.parentView,
    required this.isExpanded,
    required this.isFeedback,
    required this.level,
    required this.leftPadding,
    required this.categoryType,
    required this.showActions,
    required this.onSelected,
    this.onTertiarySelected,
    this.isDraggable = true,
  });

  final ViewPB view;
  final ViewPB? parentView;
  final bool isExpanded;

  /// Identify if the view item is rendered as feedback
  /// widget inside DraggableItem
  final bool isFeedback;

  final int level;
  final double leftPadding;
  final FolderCategoryType categoryType;
  final bool showActions;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;
  final bool isDraggable;

  @override
  State<SingleInnerViewItem> createState() => _SingleInnerViewItemState();
}

class _SingleInnerViewItemState extends State<SingleInnerViewItem> {
  @override
  Widget build(BuildContext context) {
    if (widget.isFeedback) {
      return _buildViewItem(false);
    }

    return FlowyHover(
      style: HoverStyle(
        hoverColor: Theme.of(context).colorScheme.secondary,
      ),
      resetHoverOnRebuild: widget.showActions,
      buildWhenOnHover: () => !widget.showActions && !_isDragging,
      builder: (_, onHover) => _buildViewItem(onHover),
      isSelected: () =>
          widget.showActions ||
          getIt<MenuSharedState>().latestOpenView?.id == widget.view.id,
    );
  }

  Widget _buildViewItem(bool onHover) {
    final children = [
      // Expand icon
      _buildLeftIcon(),
      // Icon
      SizedBox.square(
        dimension: 16,
        child: widget.view.defaultIcon(),
      ),
      const HSpace(5),
      // Title
      Expanded(
        child: FlowyText.regular(
          widget.view.name,
          overflow: TextOverflow.ellipsis,
        ),
      )
    ];

    // Hover action
    if (widget.showActions || onHover) {
      // ··· more action button
      children.add(_buildViewMoreActionButton(context));
      // only support add button for document layout
      if (widget.view.layout == ViewLayoutPB.Document) {
        // + button
        children.add(_buildViewAddButton(context));
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => widget.onSelected(widget.view),
      onTertiaryTapDown: (_) => widget.onTertiarySelected?.call(widget.view),
      child: SizedBox(
        height: 26,
        child: Padding(
          padding: EdgeInsets.only(left: widget.level * widget.leftPadding),
          child: Row(children: children),
        ),
      ),
    );
  }

  // > button or · button
  // show > if the view is expandable.
  // show · if the view can't contain child views.
  Widget _buildLeftIcon() {
    if (isReferencedDatabaseView(widget.view, widget.parentView)) {
      return const _DotIconWidget();
    }

    return GestureDetector(
      onTap: () => context
          .read<ViewBloc>()
          .add(ViewEvent.setIsExpanded(!widget.isExpanded)),
      child: FlowySvg(
        widget.isExpanded
            ? FlowySvgs.drop_menu_show_m
            : FlowySvgs.drop_menu_hide_m,
        size: const Size.square(16.0),
      ),
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
              (viewName) {
                if (viewName.isNotEmpty) {
                  context.read<ViewBloc>().add(
                        ViewEvent.createView(
                          viewName,
                          pluginBuilder.layoutType!,
                          openAfterCreated: openAfterCreated,
                        ),
                      );
                }
              },
            );
          }

          context.read<ViewBloc>().add(const ViewEvent.setIsExpanded(true));
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
        onEditing: (value) =>
            context.read<ViewBloc>().add(ViewEvent.setIsEditing(value)),
        onAction: (action) {
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
                confirm: (newValue) =>
                    context.read<ViewBloc>().add(ViewEvent.rename(newValue)),
              ).show(context);
              break;
            case ViewMoreActionType.delete:
              context.read<ViewBloc>().add(const ViewEvent.delete());
              break;
            case ViewMoreActionType.duplicate:
              context.read<ViewBloc>().add(const ViewEvent.duplicate());
              break;
            case ViewMoreActionType.openInNewTab:
              context
                  .read<PanesBloc>()
                  .add(OpenTabInActivePane(plugin: widget.view.plugin()));
              break;
            case ViewMoreActionType.splitDown:
              context.read<PanesBloc>().add(
                    SplitPane(
                      plugin: widget.view.plugin(),
                      splitDirection: SplitDirection.down,
                    ),
                  );

            case ViewMoreActionType.splitRight:
              context.read<PanesBloc>().add(
                    SplitPane(
                      plugin: widget.view.plugin(),
                      splitDirection: SplitDirection.right,
                    ),
                  );
            default:
              throw UnsupportedError('$action is not supported');
          }
        },
      ),
    );
  }

  String _convertLayoutToHintText(ViewLayoutPB layout) => switch (layout) {
        ViewLayoutPB.Document => LocaleKeys.newDocumentText.tr(),
        ViewLayoutPB.Grid => LocaleKeys.newGridText.tr(),
        ViewLayoutPB.Board => LocaleKeys.newBoardText.tr(),
        ViewLayoutPB.Calendar => LocaleKeys.newCalendarText.tr(),
        _ => LocaleKeys.newPageText.tr(),
      };
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
