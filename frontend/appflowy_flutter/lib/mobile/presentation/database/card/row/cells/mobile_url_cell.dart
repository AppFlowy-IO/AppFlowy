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

class MobileURLCell extends GridCellWidget {
  MobileURLCell({
    super.key,
    required this.cellControllerBuilder,
    this.hintText,
  });

  final CellControllerBuilder cellControllerBuilder;
  final String? hintText;

  @override
  GridCellState<MobileURLCell> createState() => _GridURLCellState();
}

class _GridURLCellState extends GridCellState<MobileURLCell> {
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
          if (content.isEmpty) {
            return TextField(
              focusNode: _focusNode,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hintText,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
              // close keyboard when tapping outside of the text field
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (value) =>
                  _cellBloc.add(URLCellEvent.updateURL(value)),
            );
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                if (content.isEmpty) {
                  return;
                }
                final shouldAddScheme = !['http', 'https']
                    .any((pattern) => content.startsWith(pattern));
                final url = shouldAddScheme ? 'http://$content' : content;
                canLaunchUrlString(url).then((value) => launchUrlString(url));
              },
              onLongPress: () => showFlowyMobileBottomSheet(
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
              ),
              child: Text(
                content,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: TextDecoration.underline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void requestBeginFocus() {
    _focusNode.requestFocus();
  }
}
