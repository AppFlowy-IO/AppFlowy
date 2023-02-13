import 'package:app_flowy/plugins/document/presentation/plugins/base/insert_page_command.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:app_flowy/workspace/application/view/view_ext.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';

class BuiltInPageWidget extends StatefulWidget {
  const BuiltInPageWidget({
    Key? key,
    required this.node,
    required this.editorState,
    required this.builder,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;
  final Widget Function(ViewPB viewPB) builder;

  @override
  State<BuiltInPageWidget> createState() => _BuiltInPageWidgetState();
}

class _BuiltInPageWidgetState extends State<BuiltInPageWidget> {
  final focusNode = FocusNode();

  String get gridID {
    return widget.node.attributes[kViewID];
  }

  String get appID {
    return widget.node.attributes[kAppID];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dartz.Either<ViewPB, FlowyError>>(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final board = snapshot.data?.getLeftOrNull<ViewPB>();
          if (board != null) {
            return _build(context, board);
          }
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      future: AppService().getView(appID, gridID),
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  Widget _build(BuildContext context, ViewPB viewPB) {
    return MouseRegion(
      onEnter: (event) {
        widget.editorState.service.scrollService?.disable();
      },
      onExit: (event) {
        widget.editorState.service.scrollService?.enable();
      },
      child: SizedBox(
        height: 400,
        child: Stack(
          children: [
            _buildMenu(context, viewPB),
            _buildGrid(context, viewPB),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, ViewPB viewPB) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (value) {
        if (value) {
          widget.editorState.service.selectionService.clearSelection();
        }
      },
      child: widget.builder(viewPB),
    );
  }

  Widget _buildMenu(BuildContext context, ViewPB viewPB) {
    return Positioned(
      top: 5,
      left: 5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // information
          FlowyIconButton(
            tooltipText: LocaleKeys.tooltip_referencePage.tr(namedArgs: {
              'name': viewPB.layout.name,
            }),
            width: 24,
            height: 24,
            iconPadding: const EdgeInsets.all(3),
            icon: svgWidget('common/information'),
          ),
          // Name
          const Space(7, 0),
          FlowyText.medium(
            viewPB.name,
            fontSize: 16.0,
          ),
          // setting
          const Space(7, 0),
          PopoverActionList<_ActionWrapper>(
            direction: PopoverDirection.bottomWithCenterAligned,
            actions: _ActionType.values
                .map((action) => _ActionWrapper(action))
                .toList(),
            buildChild: (controller) {
              return FlowyIconButton(
                tooltipText: LocaleKeys.tooltip_openMenu.tr(),
                width: 24,
                height: 24,
                iconPadding: const EdgeInsets.all(3),
                icon: svgWidget('common/settings'),
                onPressed: () => controller.show(),
              );
            },
            onSelected: (action, controller) async {
              switch (action.inner) {
                case _ActionType.viewDatabase:
                  getIt<MenuSharedState>().latestOpenView = viewPB;
                  getIt<HomeStackManager>().setPlugin(viewPB.plugin());
                  break;
                case _ActionType.delete:
                  final transaction = widget.editorState.transaction;
                  transaction.deleteNode(widget.node);
                  widget.editorState.apply(transaction);
                  break;
              }
              controller.close();
            },
          )
        ],
      ),
    );
  }
}

enum _ActionType {
  viewDatabase,
  delete,
}

class _ActionWrapper extends ActionCell {
  final _ActionType inner;

  _ActionWrapper(this.inner);

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    switch (inner) {
      case _ActionType.viewDatabase:
        return LocaleKeys.tooltip_viewDataBase.tr();
      case _ActionType.delete:
        return LocaleKeys.disclosureAction_delete.tr();
    }
  }
}
