import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/shortcuts.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/toolbar/grid_setting_bar.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/setting_menu.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopGridTabBarBuilderImpl extends DatabaseTabBarItemBuilder {
  final _toggleExtension = ToggleExtensionNotifier();

  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
    String? initialRowId,
  ) {
    return GridPage(
      key: _makeValueKey(controller),
      view: view,
      databaseController: controller,
      initialRowId: initialRowId,
      shrinkWrap: shrinkWrap,
    );
  }

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) {
    return GridSettingBar(
      key: _makeValueKey(controller),
      controller: controller,
      toggleExtension: _toggleExtension,
    );
  }

  @override
  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  ) {
    return DatabaseViewSettingExtension(
      key: _makeValueKey(controller),
      viewId: controller.viewId,
      databaseController: controller,
      toggleExtension: _toggleExtension,
    );
  }

  @override
  void dispose() {
    _toggleExtension.dispose();
    super.dispose();
  }

  ValueKey _makeValueKey(DatabaseController controller) {
    return ValueKey(controller.viewId);
  }
}

class BuiltInGridPage extends StatefulWidget {
  const BuiltInGridPage({
    super.key,
    required this.view,
    required this.databaseController,
  });

  final ViewPB view;
  final DatabaseController databaseController;

  @override
  State<BuiltInGridPage> createState() => _BuiltInGridPageState();
}

class _BuiltInGridPageState extends State<BuiltInGridPage> {
  late final GridBloc gridBloc;

  @override
  void initState() {
    super.initState();
    gridBloc = GridBloc(
      view: widget.view,
      databaseController: widget.databaseController,
    )..add(const GridEvent.initial());
  }

  @override
  void dispose() {
    gridBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: gridBloc,
      child: BlocBuilder<GridBloc, GridState>(
        buildWhen: (prev, curr) => prev.loadingState != curr.loadingState,
        builder: (_, state) => state.loadingState.map(
          idle: (_) => const SizedBox.shrink(),
          loading: (_) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          finish: (result) => result.successOrFail.fold(
            (_) => GridShortcuts(
              child: GridPageContent(
                key: ValueKey(widget.view.id),
                view: widget.view,
                shrinkWrap: true,
              ),
            ),
            (err) => Center(child: AppFlowyErrorPage(error: err)),
          ),
        ),
      ),
    );
  }
}
