import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/widgets/database_layout_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

/// [DatabaseViewLayoutPicker] is seen when changing the layout type of a
/// database view or creating a new database view.
class DatabaseViewLayoutPicker extends StatelessWidget {
  const DatabaseViewLayoutPicker({
    super.key,
    required this.selectedLayout,
    required this.onSelect,
  });

  final DatabaseLayoutPB selectedLayout;
  final void Function(DatabaseLayoutPB layout) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildButton(DatabaseLayoutPB.Grid, true),
        _buildButton(DatabaseLayoutPB.Board, false),
        _buildButton(DatabaseLayoutPB.Calendar, false),
      ],
    );
  }

  Widget _buildButton(DatabaseLayoutPB layout, bool showTopBorder) {
    return FlowyOptionTile.checkbox(
      text: layout.layoutName,
      leftIcon: FlowySvg(layout.icon, size: const Size.square(20)),
      isSelected: selectedLayout == layout,
      showTopBorder: showTopBorder,
      onTap: () {
        onSelect(layout);
      },
    );
  }
}

class MobileCalendarViewLayoutSettings extends StatelessWidget {
  const MobileCalendarViewLayoutSettings({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _layoutField(),
        _divider(),
        ..._startWeek(context),
      ],
    );
  }

  Widget _layoutField() {
    return FlowyOptionTile.text(
      text: LocaleKeys.calendar_settings_layoutDateField.tr(),
    );
  }

  Widget _divider() => const VSpace(20);

  List<Widget> _startWeek(BuildContext context) {
    final symbols = DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
        child: FlowyText(
          LocaleKeys.calendar_settings_firstDayOfWeek.tr().toUpperCase(),
          fontSize: 13,
          color: Theme.of(context).hintColor,
        ),
      ),
      FlowyOptionTile.checkbox(
        text: symbols.WEEKDAYS[-1],
        isSelected: true,
        onTap: () {},
      ),
      FlowyOptionTile.checkbox(
        text: symbols.WEEKDAYS[0],
        isSelected: false,
        showTopBorder: false,
        onTap: () {},
      ),
    ];
  }
}

class MobileBoardViewLayoutSettings extends StatelessWidget {
  const MobileBoardViewLayoutSettings({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(text: LocaleKeys.board_groupBy.tr());
  }
}
