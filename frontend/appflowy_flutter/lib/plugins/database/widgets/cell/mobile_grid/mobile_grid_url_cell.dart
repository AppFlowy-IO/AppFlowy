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

class MobileGridURLCellSkin extends IEditableURLCellSkin {
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
        if (content.isEmpty) {
          return TextField(
            focusNode: focusNode,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              isCollapsed: true,
            ),
            onTapOutside: (event) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            onSubmitted: (value) => bloc.add(URLCellEvent.updateURL(value)),
          );
        }

        return GestureDetector(
          onTap: () {
            if (content.isEmpty) {
              return;
            }
            final shouldAddScheme = !['http', 'https']
                .any((pattern) => content.startsWith(pattern));
            final url = shouldAddScheme ? 'http://$content' : content;
            canLaunchUrlString(url).then((value) => launchUrlString(url));
          },
          onLongPress: () => showMobileBottomSheet(
            context,
            title: LocaleKeys.board_mobile_editURL.tr(),
            showHeader: true,
            showCloseButton: true,
            builder: (_) {
              final controller = TextEditingController(text: content);
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
          ),
          child: Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                content,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: TextDecoration.underline,
                      color: Theme.of(context).colorScheme.primary,
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
}
