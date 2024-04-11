import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/mobile_card_detail_screen.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Widget getGridFabs(BuildContext context) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      MobileGridFab(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).primaryColor,
        onTap: () {
          final bloc = context.read<GridBloc>();
          if (bloc.state.rowInfos.isNotEmpty) {
            context.push(
              MobileRowDetailPage.routeName,
              extra: {
                MobileRowDetailPage.argRowId: bloc.state.rowInfos.first.rowId,
                MobileRowDetailPage.argDatabaseController:
                    bloc.databaseController,
              },
            );
          }
        },
        boxShadow: const BoxShadow(
          offset: Offset(0, 8),
          color: Color(0x145D7D8B),
          blurRadius: 20,
        ),
        icon: FlowySvgs.properties_s,
        iconSize: const Size.square(24),
      ),
      const HSpace(16),
      MobileGridFab(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onTap: () {
          context
              .read<GridBloc>()
              .add(const GridEvent.createRow(openRowDetail: true));
        },
        overlayColor: const MaterialStatePropertyAll<Color>(Color(0xFF009FD1)),
        boxShadow: const BoxShadow(
          offset: Offset(0, 8),
          color: Color(0x6612BFEF),
          blurRadius: 18,
          spreadRadius: -5,
        ),
        icon: FlowySvgs.add_s,
        iconSize: const Size.square(24),
      ),
    ],
  );
}

class MobileGridFab extends StatelessWidget {
  const MobileGridFab({
    super.key,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.boxShadow,
    required this.onTap,
    required this.icon,
    required this.iconSize,
    this.overlayColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final BoxShadow boxShadow;
  final VoidCallback onTap;
  final FlowySvgData icon;
  final Size iconSize;
  final MaterialStateProperty<Color?>? overlayColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border.fromBorderSide(
          BorderSide(width: 0.5, color: Color(0xFFE4EDF0)),
        ),
        borderRadius: radius,
        boxShadow: [boxShadow],
      ),
      child: Material(
        borderOnForeground: false,
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          overlayColor: overlayColor,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 56,
            child: Center(
              child: FlowySvg(
                icon,
                color: foregroundColor,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
