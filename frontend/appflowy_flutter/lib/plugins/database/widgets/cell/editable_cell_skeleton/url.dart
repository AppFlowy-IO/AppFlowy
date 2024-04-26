import 'dart:async';
import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../desktop_grid/desktop_grid_url_cell.dart';
import '../desktop_row_detail/desktop_row_detail_url_cell.dart';
import '../mobile_grid/mobile_grid_url_cell.dart';
import '../mobile_row_detail/mobile_row_detail_url_cell.dart';

abstract class IEditableURLCellSkin {
  const IEditableURLCellSkin();

  factory IEditableURLCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridURLSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailURLSkin(),
      EditableCellStyle.mobileGrid => MobileGridURLCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailURLCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    URLCellDataNotifier cellDataNotifier,
  );

  List<GridCellAccessoryBuilder> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  );
}

typedef URLCellDataNotifier = CellDataNotifier<String>;

class EditableURLCell extends EditableCellWidget {
  EditableURLCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  }) : _cellDataNotifier = CellDataNotifier(value: '');

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableURLCellSkin skin;
  final URLCellDataNotifier _cellDataNotifier;

  @override
  List<GridCellAccessoryBuilder> Function(
    GridCellAccessoryBuildContext buildContext,
  ) get accessoryBuilder => (context) {
        return skin.accessoryBuilder(context, _cellDataNotifier);
      };

  @override
  GridCellState<EditableURLCell> createState() => _GridURLCellState();
}

class _GridURLCellState extends GridEditableTextCell<EditableURLCell> {
  late final TextEditingController _textEditingController;
  late final cellBloc = URLCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: cellBloc.state.content);
  }

  @override
  void dispose() {
    widget._cellDataNotifier.dispose();
    _textEditingController.dispose();
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocListener<URLCellBloc, URLCellState>(
        listenWhen: (previous, current) => previous.content != current.content,
        listener: (context, state) {
          _textEditingController.value =
              _textEditingController.value.copyWith(text: state.content);
          widget._cellDataNotifier.value = state.content;
        },
        child: widget.skin.build(
          context,
          widget.cellContainerNotifier,
          cellBloc,
          focusNode,
          _textEditingController,
          widget._cellDataNotifier,
        ),
      ),
    );
  }

  @override
  Future<void> focusChanged() async {
    if (mounted &&
        !cellBloc.isClosed &&
        cellBloc.state.content != _textEditingController.text) {
      cellBloc.add(URLCellEvent.updateURL(_textEditingController.text));
    }
    return super.focusChanged();
  }

  @override
  String? onCopy() => cellBloc.state.content;
}

class MobileURLEditor extends StatelessWidget {
  const MobileURLEditor({
    super.key,
    required this.textEditingController,
  });

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VSpace(4.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FlowyTextField(
            controller: textEditingController,
            hintStyle: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).hintColor),
            hintText: LocaleKeys.grid_url_textFieldHint.tr(),
            textStyle: Theme.of(context).textTheme.bodyMedium,
            keyboardType: TextInputType.url,
            hintTextConstraints: const BoxConstraints(maxHeight: 52),
            error: context.watch<URLCellBloc>().state.isValid
                ? null
                : const SizedBox.shrink(),
            onChanged: (_) {
              if (textEditingController.value.composing.isCollapsed) {
                context
                    .read<URLCellBloc>()
                    .add(URLCellEvent.updateURL(textEditingController.text));
              }
            },
            onSubmitted: (text) =>
                context.read<URLCellBloc>().add(URLCellEvent.updateURL(text)),
          ),
        ),
        const VSpace(8.0),
        MobileQuickActionButton(
          enable: context.watch<URLCellBloc>().state.content.isNotEmpty,
          onTap: () {
            openUrlCellLink(textEditingController.text);
            context.pop();
          },
          icon: FlowySvgs.url_s,
          text: LocaleKeys.grid_url_launch.tr(),
        ),
        const Divider(height: 8.5, thickness: 0.5),
        MobileQuickActionButton(
          enable: context.watch<URLCellBloc>().state.content.isNotEmpty,
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: textEditingController.text),
            );
            Fluttertoast.showToast(
              msg: LocaleKeys.grid_url_copiedNotification.tr(),
              gravity: ToastGravity.BOTTOM,
            );
            context.pop();
          },
          icon: FlowySvgs.copy_s,
          text: LocaleKeys.grid_url_copy.tr(),
        ),
        const Divider(height: 8.5, thickness: 0.5),
      ],
    );
  }
}

void openUrlCellLink(String content) async {
  late Uri uri;

  try {
    uri = Uri.parse(content);
    if (!uri.hasScheme || uri.scheme == "localhost") {
      uri = Uri.parse('http://$content');
      await InternetAddress.lookup(uri.host);
    }
  } catch (_) {
    uri = Uri.parse(
      "https://www.google.com/search?q=${Uri.encodeComponent(content)}",
    );
  } finally {
    await launchUrl(uri);
  }
}
