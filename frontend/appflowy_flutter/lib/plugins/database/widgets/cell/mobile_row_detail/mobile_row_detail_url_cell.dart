import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../editable_cell_skeleton/url.dart';

class MobileRowDetailURLCellSkin extends IEditableURLCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return BlocSelector<URLCellBloc, URLCellState, String>(
      selector: (state) => state.content,
      builder: (context, content) {
        return InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          onTap: () {
            if (content.isEmpty) {
              _showURLEditor(context, bloc, content);
              return;
            }
            final shouldAddScheme = !['http', 'https']
                .any((pattern) => content.startsWith(pattern));
            final url = shouldAddScheme ? 'http://$content' : content;
            canLaunchUrlString(url).then((value) => launchUrlString(url));
          },
          onLongPress: () => _showURLEditor(context, bloc, content),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 48,
              minWidth: double.infinity,
            ),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text(
                content.isEmpty
                    ? LocaleKeys.grid_row_textPlaceholder.tr()
                    : content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      decoration:
                          content.isEmpty ? null : TextDecoration.underline,
                      color: content.isEmpty
                          ? Theme.of(context).hintColor
                          : Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  List<GridCellAccessoryBuilder<State<StatefulWidget>>> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  ) =>
      const [];

  void _showURLEditor(BuildContext context, URLCellBloc bloc, String content) {
    final controller = TextEditingController(text: content);
    showMobileBottomSheet(
      context,
      title: LocaleKeys.board_mobile_editURL.tr(),
      showHeader: true,
      showCloseButton: true,
      builder: (_) {
        return TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          onEditingComplete: () {
            bloc.add(URLCellEvent.updateURL(controller.text));
            context.pop();
          },
        );
      },
    ).then((_) => controller.dispose());
  }
}
