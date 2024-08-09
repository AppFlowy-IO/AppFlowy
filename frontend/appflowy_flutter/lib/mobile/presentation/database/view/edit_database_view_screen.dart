import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy/plugins/database/domain/layout_service.dart';
import 'package:appflowy/plugins/database/widgets/database_layout_ext.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'database_field_list.dart';
import 'database_view_layout.dart';

/// [MobileEditDatabaseViewScreen] is the main widget used to edit a database
/// view. It contains multiple sub-pages, and the current page is managed by
/// [MobileEditDatabaseViewCubit]
class MobileEditDatabaseViewScreen extends StatelessWidget {
  const MobileEditDatabaseViewScreen({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewBloc, ViewState>(
      builder: (context, state) {
        return Column(
          children: [
            _NameAndIcon(view: state.view),
            _divider(),
            DatabaseViewSettingTile(
              setting: DatabaseViewSettings.layout,
              databaseController: databaseController,
              view: state.view,
              showTopBorder: true,
            ),
            if (databaseController.databaseLayout == DatabaseLayoutPB.Calendar)
              DatabaseViewSettingTile(
                setting: DatabaseViewSettings.calendar,
                databaseController: databaseController,
                view: state.view,
              ),
            DatabaseViewSettingTile(
              setting: DatabaseViewSettings.fields,
              databaseController: databaseController,
              view: state.view,
            ),
            _divider(),
          ],
        );
      },
    );
  }

  Widget _divider() => const VSpace(20);
}

class _NameAndIcon extends StatefulWidget {
  const _NameAndIcon({required this.view});

  final ViewPB view;

  @override
  State<_NameAndIcon> createState() => _NameAndIconState();
}

class _NameAndIconState extends State<_NameAndIcon> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textEditingController.text = widget.view.name;
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FlowyOptionTile.textField(
        autofocus: true,
        showTopBorder: false,
        controller: textEditingController,
        onTextChanged: (text) {
          context.read<ViewBloc>().add(ViewEvent.rename(text));
        },
      ),
    );
  }
}

enum DatabaseViewSettings {
  layout,
  fields,
  filter,
  sort,
  board,
  calendar,
  duplicate,
  delete;

  String get label {
    return switch (this) {
      layout => LocaleKeys.grid_settings_databaseLayout.tr(),
      fields => LocaleKeys.grid_settings_properties.tr(),
      filter => LocaleKeys.grid_settings_filter.tr(),
      sort => LocaleKeys.grid_settings_sort.tr(),
      board => LocaleKeys.grid_settings_boardSettings.tr(),
      calendar => LocaleKeys.grid_settings_calendarSettings.tr(),
      duplicate => LocaleKeys.grid_settings_duplicateView.tr(),
      delete => LocaleKeys.grid_settings_deleteView.tr(),
    };
  }

  FlowySvgData get icon {
    return switch (this) {
      layout => FlowySvgs.card_view_s,
      fields => FlowySvgs.disorder_list_s,
      filter => FlowySvgs.filter_s,
      sort => FlowySvgs.sort_ascending_s,
      board => FlowySvgs.board_s,
      calendar => FlowySvgs.calendar_s,
      duplicate => FlowySvgs.copy_s,
      delete => FlowySvgs.delete_s,
    };
  }
}

class DatabaseViewSettingTile extends StatelessWidget {
  const DatabaseViewSettingTile({
    super.key,
    required this.setting,
    required this.databaseController,
    required this.view,
    this.showTopBorder = false,
  });

  final DatabaseViewSettings setting;
  final DatabaseController databaseController;
  final ViewPB view;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: setting.label,
      leftIcon: FlowySvg(setting.icon, size: const Size.square(20)),
      trailing: _trailing(context, setting, view, databaseController),
      showTopBorder: showTopBorder,
      onTap: () => _onTap(context),
    );
  }

  Widget _trailing(
    BuildContext context,
    DatabaseViewSettings setting,
    ViewPB view,
    DatabaseController databaseController,
  ) {
    switch (setting) {
      case DatabaseViewSettings.layout:
        return Row(
          children: [
            FlowyText(
              databaseLayoutFromViewLayout(view.layout).layoutName,
              color: Theme.of(context).hintColor,
            ),
            const HSpace(8),
            const FlowySvg(FlowySvgs.arrow_right_s),
          ],
        );
      case DatabaseViewSettings.fields:
        final numVisible = databaseController.fieldController.fieldInfos
            .where((field) => field.visibility != FieldVisibility.AlwaysHidden)
            .length;
        return Row(
          children: [
            FlowyText(
              LocaleKeys.grid_settings_numberOfVisibleFields
                  .tr(args: [numVisible.toString()]),
              color: Theme.of(context).hintColor,
            ),
            const HSpace(8),
            const FlowySvg(FlowySvgs.arrow_right_s),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTap(BuildContext context) async {
    if (setting == DatabaseViewSettings.layout) {
      final databaseLayout = databaseLayoutFromViewLayout(view.layout);
      final newLayout = await showMobileBottomSheet<DatabaseLayoutPB>(
        context,
        showDragHandle: true,
        showHeader: true,
        showDivider: false,
        title: LocaleKeys.grid_settings_layout.tr(),
        builder: (context) {
          return DatabaseViewLayoutPicker(
            selectedLayout: databaseLayout,
            onSelect: (layout) => Navigator.of(context).pop(layout),
          );
        },
      );
      if (newLayout != null && newLayout != databaseLayout) {
        await DatabaseViewBackendService.updateLayout(
          viewId: databaseController.viewId,
          layout: newLayout,
        );
      }
      return;
    }

    if (setting == DatabaseViewSettings.fields) {
      await showTransitionMobileBottomSheet(
        context,
        showHeader: true,
        showBackButton: true,
        title: LocaleKeys.grid_settings_properties.tr(),
        builder: (_) {
          return BlocProvider.value(
            value: context.read<ViewBloc>(),
            child: MobileDatabaseFieldList(
              databaseController: databaseController,
              canCreate: true,
            ),
          );
        },
      );
      return;
    }

    if (setting == DatabaseViewSettings.board) {
      await showMobileBottomSheet<DatabaseLayoutPB>(
        context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 46),
            child: MobileBoardViewLayoutSettings(
              databaseController: databaseController,
            ),
          );
        },
      );
      return;
    }

    if (setting == DatabaseViewSettings.calendar) {
      await showMobileBottomSheet<DatabaseLayoutPB>(
        context,
        showDragHandle: true,
        showHeader: true,
        showDivider: false,
        title: LocaleKeys.calendar_settings_name.tr(),
        builder: (context) {
          return MobileCalendarViewLayoutSettings(
            databaseController: databaseController,
          );
        },
      );
      return;
    }

    if (setting == DatabaseViewSettings.delete) {
      context.read<ViewBloc>().add(const ViewEvent.delete());
      context.pop(true);
      return;
    }
  }
}
