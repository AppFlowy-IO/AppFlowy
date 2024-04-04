import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item_add_button.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

typedef ViewItemOnSelected = void Function(ViewPB);
typedef ActionPaneBuilder = ActionPane Function(BuildContext context);

const _itemHeight = 48.0;

class MobileViewItem extends StatelessWidget {
  const MobileViewItem({
    super.key,
    required this.view,
    this.parentView,
    required this.categoryType,
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

  final FolderCategoryType categoryType;

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
            categoryType: categoryType,
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
    required this.categoryType,
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

  final ActionPaneBuilder? startActionPane;
  final ActionPaneBuilder? endActionPane;

  @override
  Widget build(BuildContext context) {
    Widget child = SingleMobileInnerViewItem(
      view: view,
      parentView: parentView,
      level: level,
      showActions: showActions,
      categoryType: categoryType,
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
            key: ValueKey('${categoryType.name} ${childView.id}'),
            parentView: view,
            categoryType: categoryType,
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
            const Divider(
              height: 1,
            ),
            ...children,
          ],
        );
      } else {
        child = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const Divider(
              height: 1,
            ),
            Container(
              height: _itemHeight,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: (level + 2) * leftPadding),
                child: FlowyText.medium(
                  LocaleKeys.noPagesInside.tr(),
                  color: Colors.grey,
                ),
              ),
            ),
            const Divider(
              height: 1,
            ),
          ],
        );
      }
    } else {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const Divider(
            height: 1,
          ),
        ],
      );
    }

    // wrap the child with DraggableItem if isDraggable is true
    if (isDraggable && !isReferencedDatabaseView(view, parentView)) {
      child = DraggableViewItem(
        isFirstChild: isFirstChild,
        view: view,
        // FIXME: use better color
        centerHighlightColor: Colors.blue.shade200,
        topHighlightColor: Colors.blue.shade200,
        bottomHighlightColor: Colors.blue.shade200,
        feedback: (context) {
          return MobileViewItem(
            view: view,
            parentView: parentView,
            categoryType: categoryType,
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
    required this.categoryType,
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
  final FolderCategoryType categoryType;
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
      const HSpace(4),
      // icon
      _buildViewIcon(),
      const HSpace(8),
      // title
      Expanded(
        child: FlowyText.medium(
          widget.view.name,
          fontSize: 18.0,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    // hover action

    // ··· more action button
    // children.add(_buildViewMoreActionButton(context));
    // only support add button for document layout
    if (!widget.isFeedback && widget.view.layout == ViewLayoutPB.Document) {
      // + button
      children.add(_buildViewAddButton(context));
    }

    Widget child = InkWell(
      borderRadius: BorderRadius.circular(4.0),
      onTap: () => widget.onSelected(widget.view),
      child: SizedBox(
        height: _itemHeight,
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
        ? EmojiText(
            emoji: widget.view.icon.value,
            fontSize: 24.0,
          )
        : SizedBox.square(
            dimension: 26.0,
            child: widget.view.defaultIcon(),
          );
    return icon;
  }

  // > button or · button
  // show > if the view is expandable.
  // show · if the view can't contain child views.
  Widget _buildLeftIcon() {
    if (isReferencedDatabaseView(widget.view, widget.parentView)) {
      return const _DotIconWidget();
    }

    return GestureDetector(
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 250),
        turns: widget.isExpanded ? 0 : -0.25,
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 28,
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
                        section:
                            widget.categoryType != FolderCategoryType.favorite
                                ? widget.categoryType.toViewSectionPB
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
