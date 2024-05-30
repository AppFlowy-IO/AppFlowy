import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item_add_button.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

typedef ViewItemOnSelected = void Function(ViewPB);
typedef ActionPaneBuilder = ActionPane Function(BuildContext context);

class MobileViewItem extends StatelessWidget {
  const MobileViewItem({
    super.key,
    required this.view,
    this.parentView,
    required this.spaceType,
    required this.level,
    this.leftPadding = 10,
    required this.onSelected,
    this.isFirstChild = false,
    this.isDraggable = true,
    required this.isFeedback,
    this.startActionPane,
    this.endActionPane,
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

  // used for indicating the first child of the parent view, so that we can
  // add top border to the first child
  final bool isFirstChild;

  // it should be false when it's rendered as feedback widget inside DraggableItem
  final bool isDraggable;

  // identify if the view item is rendered as feedback widget inside DraggableItem
  final bool isFeedback;

  // the actions of the view item, such as favorite, rename, delete, etc.
  final ActionPaneBuilder? startActionPane;
  final ActionPaneBuilder? endActionPane;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewBloc(view: view)..add(const ViewEvent.initial()),
      child: BlocConsumer<ViewBloc, ViewState>(
        listenWhen: (p, c) =>
            c.lastCreatedView != null &&
            p.lastCreatedView?.id != c.lastCreatedView!.id,
        listener: (context, state) => context.pushView(state.lastCreatedView!),
        builder: (context, state) {
          return InnerMobileViewItem(
            view: state.view,
            parentView: parentView,
            childViews: state.view.childViews,
            spaceType: spaceType,
            level: level,
            leftPadding: leftPadding,
            showActions: true,
            isExpanded: state.isExpanded,
            onSelected: onSelected,
            isFirstChild: isFirstChild,
            isDraggable: isDraggable,
            isFeedback: isFeedback,
            startActionPane: startActionPane,
            endActionPane: endActionPane,
          );
        },
      ),
    );
  }
}

class InnerMobileViewItem extends StatelessWidget {
  const InnerMobileViewItem({
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
    this.isFirstChild = false,
    required this.isFeedback,
    this.startActionPane,
    this.endActionPane,
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

  final ActionPaneBuilder? startActionPane;
  final ActionPaneBuilder? endActionPane;

  @override
  Widget build(BuildContext context) {
    Widget child = SingleMobileInnerViewItem(
      view: view,
      parentView: parentView,
      level: level,
      showActions: showActions,
      spaceType: spaceType,
      onSelected: onSelected,
      isExpanded: isExpanded,
      isDraggable: isDraggable,
      leftPadding: leftPadding,
      isFeedback: isFeedback,
      startActionPane: startActionPane,
      endActionPane: endActionPane,
    );

    // if the view is expanded and has child views, render its child views
    if (isExpanded) {
      if (childViews.isNotEmpty) {
        final children = childViews.map((childView) {
          return MobileViewItem(
            key: ValueKey('${spaceType.name} ${childView.id}'),
            parentView: view,
            spaceType: spaceType,
            isFirstChild: childView.id == childViews.first.id,
            view: childView,
            level: level + 1,
            onSelected: onSelected,
            isDraggable: isDraggable,
            leftPadding: leftPadding,
            isFeedback: isFeedback,
            startActionPane: startActionPane,
            endActionPane: endActionPane,
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
    }

    // wrap the child with DraggableItem if isDraggable is true
    if (isDraggable && !isReferencedDatabaseView(view, parentView)) {
      child = DraggableViewItem(
        isFirstChild: isFirstChild,
        view: view,
        centerHighlightColor: Colors.blue.shade200,
        topHighlightColor: Colors.blue.shade200,
        bottomHighlightColor: Colors.blue.shade200,
        feedback: (context) {
          return MobileViewItem(
            view: view,
            parentView: parentView,
            spaceType: spaceType,
            level: level,
            onSelected: onSelected,
            isDraggable: false,
            leftPadding: leftPadding,
            isFeedback: true,
            startActionPane: startActionPane,
            endActionPane: endActionPane,
          );
        },
        child: child,
      );
    }

    return child;
  }
}

class SingleMobileInnerViewItem extends StatefulWidget {
  const SingleMobileInnerViewItem({
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
    required this.isFeedback,
    this.startActionPane,
    this.endActionPane,
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
  final FolderSpaceType spaceType;
  final ActionPaneBuilder? startActionPane;
  final ActionPaneBuilder? endActionPane;

  @override
  State<SingleMobileInnerViewItem> createState() =>
      _SingleMobileInnerViewItemState();
}

class _SingleMobileInnerViewItemState extends State<SingleMobileInnerViewItem> {
  @override
  Widget build(BuildContext context) {
    final children = [
      // expand icon
      _buildLeftIcon(),
      // icon
      _buildViewIcon(),
      const HSpace(8),
      // title
      Expanded(
        child: FlowyText.regular(
          widget.view.name,
          fontSize: 16.0,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    // hover action

    // ··· more action button
    children.add(_buildViewMoreButton(context));
    // only support add button for document layout
    if (!widget.isFeedback && widget.view.layout == ViewLayoutPB.Document) {
      // + button

      children.add(_buildViewAddButton(context));
    }

    Widget child = InkWell(
      borderRadius: BorderRadius.circular(4.0),
      onTap: () => widget.onSelected(widget.view),
      child: SizedBox(
        height: HomeSpaceViewSizes.mViewHeight,
        child: Padding(
          padding: EdgeInsets.only(left: widget.level * widget.leftPadding),
          child: Row(
            children: children,
          ),
        ),
      ),
    );

    if (widget.startActionPane != null || widget.endActionPane != null) {
      child = Slidable(
        // Specify a key if the Slidable is dismissible.
        key: ValueKey(widget.view.hashCode),
        startActionPane: widget.startActionPane?.call(context),
        endActionPane: widget.endActionPane?.call(context),
        child: child,
      );
    }

    return child;
  }

  Widget _buildViewIcon() {
    final icon = widget.view.icon.value.isNotEmpty
        ? FlowyText.emoji(
            widget.view.icon.value,
            fontSize: 20.0,
          )
        : SizedBox.square(
            dimension: 18.0,
            child: widget.view.defaultIcon(),
          );
    return icon;
  }

  // > button or · button
  // show > if the view is expandable.
  // show · if the view can't contain child views.
  Widget _buildLeftIcon() {
    if (context.read<ViewBloc>().state.view.childViews.isEmpty) {
      return HSpace(widget.leftPadding);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(right: 6.0, top: 6.0, bottom: 6.0),
        child: widget.isExpanded
            ? const FlowySvg(
                FlowySvgs.m_expand_s,
                blendMode: null,
              )
            : const FlowySvg(
                FlowySvgs.m_collapse_s,
                blendMode: null,
              ),
      ),
      onTap: () {
        context
            .read<ViewBloc>()
            .add(ViewEvent.setIsExpanded(!widget.isExpanded));
      },
    );
  }

  // + button
  Widget _buildViewAddButton(BuildContext context) {
    return MobileViewAddButton(
      onPressed: () {
        final title = widget.view.name;
        showMobileBottomSheet(
          context,
          showHeader: true,
          title: title,
          showDragHandle: true,
          showCloseButton: true,
          useRootNavigator: true,
          builder: (sheetContext) {
            return AddNewPageWidgetBottomSheet(
              view: widget.view,
              onAction: (layout) {
                Navigator.of(sheetContext).pop();
                context.read<ViewBloc>().add(
                      ViewEvent.createView(
                        LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                        layout,
                        section: widget.spaceType != FolderSpaceType.favorite
                            ? widget.spaceType.toViewSectionPB
                            : null,
                      ),
                    );
              },
            );
          },
        );
      },
    );
  }

  // + button
  Widget _buildViewMoreButton(BuildContext context) {
    return MobileViewMoreButton(onPressed: () => _showMoreActions(context));
  }

  Future<void> _showMoreActions(BuildContext context) async {
    final viewBloc = context.read<ViewBloc>();
    final favoriteBloc = context.read<FavoriteBloc>();
    await showMobileBottomSheet(
      context,
      showHeader: true,
      title: widget.view.name,
      showDragHandle: true,
      showCloseButton: true,
      useRootNavigator: true,
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: viewBloc),
            BlocProvider.value(value: favoriteBloc),
          ],
          child: BlocBuilder<ViewBloc, ViewState>(
            builder: (context, state) {
              final isFavorite = state.view.isFavorite;
              return MobileViewItemBottomSheet(
                view: viewBloc.state.view,
                actions: [
                  isFavorite
                      ? MobileViewItemBottomSheetBodyAction.removeFromFavorites
                      : MobileViewItemBottomSheetBodyAction.addToFavorites,
                  MobileViewItemBottomSheetBodyAction.divider,
                  MobileViewItemBottomSheetBodyAction.rename,
                  MobileViewItemBottomSheetBodyAction.divider,
                  MobileViewItemBottomSheetBodyAction.duplicate,
                  MobileViewItemBottomSheetBodyAction.divider,
                  MobileViewItemBottomSheetBodyAction.delete,
                ],
              );
            },
          ),
        );
      },
    );
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
