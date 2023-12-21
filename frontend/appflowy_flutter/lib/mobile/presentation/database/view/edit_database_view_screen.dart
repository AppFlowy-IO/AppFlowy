import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/database_view/application/layout/layout_service.dart';
import 'package:appflowy/plugins/database_view/widgets/database_layout_ext.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'database_field_list.dart';
import 'database_view_layout.dart';
import 'edit_database_view_cubit.dart';

/// [MobileEditDatabaseViewScreen] is the main widget used to edit a database
/// view. It contains multiple sub-pages, and the current page is managed by
/// [MobileEditDatabaseViewCubit]
class MobileEditDatabaseViewScreen extends StatefulWidget {
  const MobileEditDatabaseViewScreen({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  State<MobileEditDatabaseViewScreen> createState() =>
      _MobileEditDatabaseViewScreenState();
}

class _MobileEditDatabaseViewScreenState
    extends State<MobileEditDatabaseViewScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<MobileEditDatabaseViewCubit>(
      create: (context) => MobileEditDatabaseViewCubit(),
      child: BlocBuilder<MobileEditDatabaseViewCubit,
          MobileDatabaseViewEditorState>(
        builder: (context, state) {
          return switch (state.currentPage) {
            MobileEditDatabaseViewPageEnum.main => _EditDatabaseViewMainPage(
                databaseController: widget.databaseController,
              ),
            MobileEditDatabaseViewPageEnum.fields => _wrapSubPage(
                context,
                MobileDatabaseFieldList(
                  databaseController: widget.databaseController,
                ),
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _wrapSubPage(BuildContext context, Widget child) {
    return PopScope(
      canPop: false,
      child: child,
      onPopInvoked: (_) {
        context
            .read<MobileEditDatabaseViewCubit>()
            .changePage(MobileEditDatabaseViewPageEnum.main);
      },
    );
  }
}

class _EditDatabaseViewMainPage extends StatelessWidget {
  const _EditDatabaseViewMainPage({
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 1.0,
      minChildSize: 0.0,
      builder: (context, controller) {
        return Material(
          child: Column(
            children: [
              const Center(child: DragHandler()),
              const _EditDatabaseViewHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: _EditDatabaseViewBody(
                    databaseController: databaseController,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditDatabaseViewHeader extends StatelessWidget {
  const _EditDatabaseViewHeader();

  @override
  Widget build(BuildContext context) {
    const iconWidth = 30.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FlowyIconButton(
              icon: const FlowySvg(
                FlowySvgs.close_s,
                size: Size.square(iconWidth),
              ),
              width: iconWidth,
              iconPadding: EdgeInsets.zero,
              onPressed: () => context.pop(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: FlowyText.medium(
              LocaleKeys.grid_settings_editView.tr(),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDatabaseViewBody extends StatelessWidget {
  const _EditDatabaseViewBody({
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewBloc, ViewState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
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
  Widget build(BuildContext context) {
    return FlowyOptionTile.textField(
      controller: textEditingController,
      onTextChanged: (text) {
        context.read<ViewBloc>().add(ViewEvent.rename(text));
      },
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
      calendar => FlowySvgs.date_s,
      duplicate => FlowySvgs.copy_s,
      delete => FlowySvgs.delete_s,
    };
  }

  MobileEditDatabaseViewPageEnum? get subPage {
    return switch (this) {
      fields => MobileEditDatabaseViewPageEnum.fields,
      filter => MobileEditDatabaseViewPageEnum.filter,
      sort => MobileEditDatabaseViewPageEnum.sort,
      _ => null,
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
    final subPage = setting.subPage;

    if (subPage != null) {
      context.read<MobileEditDatabaseViewCubit>().changePage(subPage);
      return;
    }

    if (setting == DatabaseViewSettings.layout) {
      final databaseLayout = databaseLayoutFromViewLayout(view.layout);
      final newLayout = await showMobileBottomSheet<DatabaseLayoutPB>(
        context,
        padding: EdgeInsets.zero,
        resizeToAvoidBottomInset: false,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 46),
            child: DatabaseViewLayoutPicker(
              selectedLayout: databaseLayout,
              onSelect: (layout) {
                Navigator.of(context).pop(layout);
              },
            ),
          );
        },
      );
      if (newLayout != null && newLayout != databaseLayout) {
        DatabaseViewBackendService.updateLayout(
          viewId: databaseController.viewId,
          layout: newLayout,
        );
      }
      return;
    }

    if (setting == DatabaseViewSettings.board) {
      showMobileBottomSheet<DatabaseLayoutPB>(
        context,
        padding: EdgeInsets.zero,
        resizeToAvoidBottomInset: false,
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
      showMobileBottomSheet<DatabaseLayoutPB>(
        context,
        padding: EdgeInsets.zero,
        resizeToAvoidBottomInset: false,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 46),
            child: MobileCalendarViewLayoutSettings(
              databaseController: databaseController,
            ),
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
