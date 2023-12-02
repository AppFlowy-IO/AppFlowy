import 'dart:async';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/url_cell/url_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RowDetailURLCell extends GridCellWidget {
  RowDetailURLCell({
    super.key,
    required this.cellControllerBuilder,
    this.hintText,
  });

  final CellControllerBuilder cellControllerBuilder;
  final String? hintText;

  @override
  GridCellState<RowDetailURLCell> createState() => _RowDetailURLCellState();
}

class _RowDetailURLCellState extends GridCellState<RowDetailURLCell> {
  late final URLCellBloc _cellBloc;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as URLCellController;
    _cellBloc = URLCellBloc(cellController: cellController)
      ..add(const URLCellEvent.initial());
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocSelector<URLCellBloc, URLCellState, String>(
        selector: (state) => state.content,
        builder: (context, content) {
          return InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            onTap: () {
              if (content.isEmpty) {
                _showURLEditor(content);
                return;
              }
              final shouldAddScheme = !['http', 'https']
                  .any((pattern) => content.startsWith(pattern));
              final url = shouldAddScheme ? 'http://$content' : content;
              canLaunchUrlString(url).then((value) => launchUrlString(url));
            },
            onLongPress: () => _showURLEditor(content),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Text(
                  content.isEmpty ? widget.hintText ?? "" : content,
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
      ),
    );
  }

  void _showURLEditor(String content) {
    showFlowyMobileBottomSheet(
      context,
      title: LocaleKeys.board_mobile_editURL.tr(),
      builder: (_) {
        final controller = TextEditingController(text: content);
        return TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          onEditingComplete: () {
            _cellBloc.add(URLCellEvent.updateURL(controller.text));
            context.pop();
          },
        );
      },
    );
  }

  @override
  void requestBeginFocus() {
    _focusNode.requestFocus();
  }
}
