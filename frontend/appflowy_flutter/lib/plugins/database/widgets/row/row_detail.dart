import 'package:appflowy/plugins/document/presentation/editor_drop_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/row_document.dart';
import 'package:appflowy/plugins/database_document/database_document_plugin.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../cell/editable_cell_builder.dart';

import 'row_banner.dart';
import 'row_property.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  const RowDetailPage({
    super.key,
    required this.rowController,
    required this.databaseController,
    this.allowOpenAsFullPage = true,
    this.userProfile,
  });

  final RowController rowController;
  final DatabaseController databaseController;
  final bool allowOpenAsFullPage;
  final UserProfilePB? userProfile;

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();
}

class _RowDetailPageState extends State<RowDetailPage> {
  // To allow blocking drop target in RowDocument from Field dialogs
  final dropManagerState = EditorDropManagerState();

  late final cellBuilder = EditableCellBuilder(
    databaseController: widget.databaseController,
  );
  late final ScrollController scrollController;

  double scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(
      onAttach: (_) => attachScrollListener(),
    );
  }

  void attachScrollListener() => scrollController.addListener(onScrollChanged);

  @override
  void dispose() {
    scrollController.removeListener(onScrollChanged);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      child: ChangeNotifierProvider.value(
        value: dropManagerState,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => RowDetailBloc(
                fieldController: widget.databaseController.fieldController,
                rowController: widget.rowController,
              ),
            ),
            BlocProvider.value(value: getIt<ReminderBloc>()),
          ],
          child: BlocBuilder<RowDetailBloc, RowDetailState>(
            builder: (context, state) => Stack(
              children: [
                ListView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    RowBanner(
                      databaseController: widget.databaseController,
                      rowController: widget.rowController,
                      cellBuilder: cellBuilder,
                      allowOpenAsFullPage: widget.allowOpenAsFullPage,
                      userProfile: widget.userProfile,
                    ),
                    const VSpace(16),
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 60),
                      child: RowPropertyList(
                        cellBuilder: cellBuilder,
                        viewId: widget.databaseController.viewId,
                        fieldController:
                            widget.databaseController.fieldController,
                      ),
                    ),
                    const VSpace(20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 60),
                      child: Divider(height: 1.0),
                    ),
                    const VSpace(20),
                    RowDocument(
                      viewId: widget.rowController.viewId,
                      rowId: widget.rowController.rowId,
                    ),
                  ],
                ),
                Positioned(
                  top: calculateActionsOffset(
                    state.rowMeta.cover.data.isNotEmpty,
                  ),
                  right: 12,
                  child: Row(
                    children: actions(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onScrollChanged() {
    if (scrollOffset != scrollController.offset) {
      setState(() => scrollOffset = scrollController.offset);
    }
  }

  double calculateActionsOffset(bool hasCover) {
    if (!hasCover) {
      return 12;
    }

    final offsetByScroll = clampDouble(
      rowCoverHeight - scrollOffset,
      0,
      rowCoverHeight,
    );
    return 12 + offsetByScroll;
  }

  List<Widget> actions(BuildContext context) {
    return [
      if (widget.allowOpenAsFullPage) ...[
        FlowyTooltip(
          message: LocaleKeys.grid_rowPage_openAsFullPage.tr(),
          child: FlowyIconButton(
            width: 20,
            height: 20,
            icon: const FlowySvg(FlowySvgs.full_view_s),
            iconColorOnHover: Theme.of(context).colorScheme.onSurface,
            onPressed: () async {
              Navigator.of(context).pop();
              final databaseId = await DatabaseViewBackendService(
                viewId: widget.databaseController.viewId,
              )
                  .getDatabaseId()
                  .then((value) => value.fold((s) => s, (f) => null));
              final documentId = widget.rowController.rowMeta.documentId;
              if (databaseId != null) {
                getIt<TabsBloc>().add(
                  TabsEvent.openPlugin(
                    plugin: DatabaseDocumentPlugin(
                      data: DatabaseDocumentContext(
                        view: widget.databaseController.view,
                        databaseId: databaseId,
                        rowId: widget.rowController.rowId,
                        documentId: documentId,
                      ),
                      pluginType: PluginType.databaseDocument,
                    ),
                    setLatest: false,
                  ),
                );
              }
            },
          ),
        ),
        const HSpace(4),
      ],
      RowActionButton(rowController: widget.rowController),
    ];
  }
}
