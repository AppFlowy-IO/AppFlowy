import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

Future<AiModel?> showChangeModelBottomSheet(
  BuildContext context,
  List<AiModel> models,
) {
  return showMobileBottomSheet<AiModel?>(
    context,
    showDragHandle: true,
    builder: (context) => _ChangeModelBottomSheetContent(models: models),
  );
}

class _ChangeModelBottomSheetContent extends StatefulWidget {
  const _ChangeModelBottomSheetContent({
    required this.models,
  });

  final List<AiModel> models;

  @override
  State<_ChangeModelBottomSheetContent> createState() =>
      _ChangeModelBottomSheetContentState();
}

class _ChangeModelBottomSheetContentState
    extends State<_ChangeModelBottomSheetContent> {
  AiModel? model;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          onCancel: () => Navigator.of(context).pop(),
          onDone: () => Navigator.of(context).pop(model),
        ),
        const VSpace(4.0),
        _Body(
          models: widget.models,
          selectedModel: model,
          onSelectModel: (format) {
            setState(() => model = format);
          },
        ),
        const VSpace(16.0),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onCancel,
    required this.onDone,
  });

  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppBarBackButton(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              onTap: onCancel,
            ),
          ),
          Align(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              child: FlowyText(
                LocaleKeys.chat_switchModel_label.tr(),
                fontSize: 17.0,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AppBarDoneButton(
              onTap: onDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.models,
    required this.selectedModel,
    required this.onSelectModel,
  });

  final List<AiModel> models;
  final AiModel? selectedModel;
  final void Function(AiModel) onSelectModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: models
          .mapIndexed(
            (index, model) => _buildModelButton(model, index == 0),
          )
          .toList(),
    );
  }

  Widget _buildModelButton(
    AiModel model, [
    bool isFirst = false,
  ]) {
    return FlowyOptionTile.checkbox(
      text: model.name,
      isSelected: model == selectedModel,
      showTopBorder: isFirst,
      onTap: () {
        onSelectModel(model);
      },
    );
  }
}
