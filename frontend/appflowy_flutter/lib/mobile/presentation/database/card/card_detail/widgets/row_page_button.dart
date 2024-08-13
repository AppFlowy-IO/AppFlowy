import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class OpenRowPageButton extends StatelessWidget {
  const OpenRowPageButton({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: double.infinity,
        minHeight: GridSize.headerHeight,
      ),
      child: TextButton.icon(
        style: Theme.of(context).textButtonTheme.style?.copyWith(
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              overlayColor: WidgetStateProperty.all<Color>(
                Theme.of(context).hoverColor,
              ),
              alignment: AlignmentDirectional.centerStart,
              splashFactory: NoSplash.splashFactory,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              ),
            ),
        label: const FlowyText.medium(
          'Open row page',
          fontSize: 15,
        ),
        icon: const Padding(
          padding: EdgeInsets.all(4.0),
          child: FlowySvg(
            FlowySvgs.full_view_s,
            size: Size.square(16.0),
          ),
        ),
        onPressed: () => _openRowPage(context),
      ),
    );
  }

  Future<void> _openRowPage(BuildContext context) async {
    final view = await ViewBackendService.getView(documentId)
        .fold((s) => s, (f) => null);
    if (view != null && context.mounted) {
      await context.pushView(view);
    }
  }
}
