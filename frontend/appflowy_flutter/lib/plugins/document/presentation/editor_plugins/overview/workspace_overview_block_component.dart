import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/application/workspace_overview/workspace_overview_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/icon.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceOverviewBlockKeys {
  const WorkspaceOverviewBlockKeys._();

  static const String type = 'overview';
  static const String backgroundColor = blockComponentBackgroundColor;
}

SelectionMenuItem workspaceOverviewItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_selectionMenu_workspaceOverview.tr(),
  iconData: Icons.list_alt,
  keywords: ['overview', 'workspace overview'],
  nodeBuilder: (editorState, _) => overviewBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

Node overviewBlockNode() => Node(type: WorkspaceOverviewBlockKeys.type);

class WorkspaceOverviewBlockComponentBuilder extends BlockComponentBuilder {
  WorkspaceOverviewBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return WorkspaceOverviewBlockWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
    );
  }

  @override
  bool validate(Node node) => node.children.isEmpty;
}

class WorkspaceOverviewBlockWidget extends BlockComponentStatefulWidget {
  const WorkspaceOverviewBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<BlockComponentStatefulWidget> createState() =>
      _OverviewBlockWidgetState();
}

class _OverviewBlockWidgetState extends State<WorkspaceOverviewBlockWidget>
    with
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin,
        BlockComponentBackgroundColorMixin,
        TickerProviderStateMixin {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  EditorState get editorState => context.read<EditorState>();

  @override
  Node get node => widget.node;

  static const double startingLeftIndent = 50.0;

  static const double leftIndentIncrementValue = 14.0;

  String get viewId => context.read<DocumentBloc>().view.id;

  final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier(true);

  bool get _isExpanded => _isExpandedNotifier.value;

  late final AnimationController _expansionController;
  late final Animation<double> _curvedAnimationExpansionController;
  static const _expansionAnimationDuration = Duration(milliseconds: 400);

  late Future<FlowyResult<ViewPB, FlowyError>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ViewBackendService.getAllLevelOfViews(viewId);
    _prepareAnimations();
  }

  @override
  void didUpdateWidget(WorkspaceOverviewBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    _expansionController.stop();
    _expansionController.dispose();
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlowyResult<ViewPB, FlowyError>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final view = snapshot.data!.toNullable();
          if (view == null) return _buildErrorWidget(viewId);

          return BlocProvider<WorkspaceOverviewBloc>(
            create: (context) => WorkspaceOverviewBloc(view: view)
              ..add(const WorkspaceOverviewEvent.initial()),
            child: BlocBuilder<WorkspaceOverviewBloc, WorkspaceOverviewState>(
              builder: (context, state) {
                return _buildOverviewBlock(state.view);
              },
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildErrorWidget(viewId);
      },
    );
  }

  void _prepareAnimations() {
    _expansionController = AnimationController(
      duration: _expansionAnimationDuration,
      reverseDuration: _expansionAnimationDuration,
      vsync: this,
    );

    _curvedAnimationExpansionController = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _runExpandCheck();
  }

  void _runExpandCheck() {
    if (_isExpanded) {
      _expansionController.forward();
    } else {
      _expansionController.reverse();
    }
  }

  Widget _buildErrorWidget(String id) {
    Log.error('Record not found for the viewId: $id');
    return const SizedBox.shrink();
  }

  Widget _buildOverviewBlock(ViewPB view) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    final children = _buildOverviewBlockChildren(
      view,
      textDirection,
      startingLeftIndent,
    );

    Widget child = Container(
      constraints: const BoxConstraints(
        minHeight: 40.0,
      ),
      padding: padding,
      child: children.isEmpty
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 5.0,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                color: backgroundColor,
              ),
              child: Column(
                key: ValueKey(children.hashCode),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                textDirection: textDirection,
                children: [
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _isExpandedNotifier,
                        builder: (context, value, _) => FlowyIconButton(
                          key: const Key("OverviewBlockExpansionIcon"),
                          onPressed: _overviewExpansionHandler,
                          icon: Icon(
                            value
                                ? Icons.arrow_drop_down_outlined
                                : Icons.arrow_right_outlined,
                            size: 25.0,
                          ),
                          hoverColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const HSpace(10.0),
                      Text(
                        LocaleKeys.document_workspaceOverviewBlock_placeholder
                            .tr(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  SizeTransition(
                    sizeFactor: _curvedAnimationExpansionController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      textDirection: textDirection,
                      children: [const VSpace(10.0), ...children],
                    ),
                  ),
                ],
              ),
            ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      if (widget.showActions && widget.actionBuilder != null) {
        child = BlockComponentActionWrapper(
          node: widget.node,
          actionBuilder: widget.actionBuilder!,
          child: child,
        );
      }
    } else {
      child = MobileBlockActionButtons(
        node: node,
        editorState: editorState,
        child: child,
      );
    }

    return child;
  }

  List<Widget> _buildOverviewBlockChildren(
    ViewPB view,
    TextDirection textDirection,
    double leftIndent,
  ) {
    final children = <Widget>[];

    children.add(
      _buildOverviewItemWidget(
        view,
        textDirection,
        leftIndent,
      ),
    );

    for (final child in view.childViews) {
      children.addAll(
        _buildOverviewBlockChildren(
          child,
          textDirection,
          leftIndent + leftIndentIncrementValue,
        ),
      );
    }

    return children;
  }

  Widget _buildOverviewItemWidget(
    ViewPB view,
    TextDirection textDirection,
    double leftIndent,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5.0),
      width: double.infinity,
      child: OverviewItemWidget(
        id: view.id,
        text: view.name,
        textDirection: textDirection,
        leftIndent: leftIndent,
        icon: view.icon,
        defaultIcon: view.defaultIcon(),
      ),
    );
  }

  void _overviewExpansionHandler() {
    _isExpandedNotifier.value = !_isExpanded;
    _runExpandCheck();
  }
}

class OverviewItemWidget extends StatelessWidget {
  const OverviewItemWidget({
    super.key,
    required this.id,
    required this.text,
    required this.textDirection,
    required this.defaultIcon,
    this.leftIndent = 0.0,
    this.icon,
  });

  final String id;
  final String text;
  final ViewIconPB? icon;
  final Widget defaultIcon;
  final TextDirection textDirection;
  final double leftIndent;

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    final textStyle = editorState.editorStyle.textStyleConfiguration;
    final style = textStyle.href.combine(textStyle.text);
    return FlowyHover(
      style: HoverStyle(hoverColor: Theme.of(context).hoverColor),
      builder: (context, onHover) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _openPage,
          child: Row(
            textDirection: textDirection,
            children: [
              HSpace(leftIndent),
              icon?.value.isNotEmpty ?? false
                  ? EmojiText(emoji: icon!.value, fontSize: 18.0)
                  : SizedBox.square(dimension: 20.0, child: defaultIcon),
              const HSpace(8.0),
              Flexible(
                child: Text(
                  text,
                  style: style.copyWith(
                    color: onHover
                        ? Theme.of(context).colorScheme.onSecondary
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPage() async {
    final view = await _fetchView(id);
    if (view == null) {
      Log.error('Page($id) not found');
      return;
    }

    getIt<TabsBloc>().add(
      TabsEvent.openPlugin(
        plugin: view.plugin(),
        view: view,
      ),
    );
  }

  Future<ViewPB?> _fetchView(String id) async {
    final view = await ViewBackendService.getView(id).then(
      (value) => value.toNullable(),
    );

    if (view == null) {
      // try to fetch from trash
      final trashViews = await TrashService().readTrash();
      final trash = trashViews.fold(
        (l) => l.items.firstWhereOrNull((element) => element.id == id),
        (r) => null,
      );
      if (trash != null) {
        return ViewPB()
          ..id = trash.id
          ..name = trash.name;
      }
    }

    return view;
  }
}
