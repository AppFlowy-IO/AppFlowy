import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectModelMenu extends StatefulWidget {
  const SelectModelMenu({
    super.key,
    required this.aiModelStateNotifier,
  });

  final AIModelStateNotifier aiModelStateNotifier;

  @override
  State<SelectModelMenu> createState() => _SelectModelMenuState();
}

class _SelectModelMenuState extends State<SelectModelMenu> {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectModelBloc(
        aiModelStateNotifier: widget.aiModelStateNotifier,
      ),
      child: BlocBuilder<SelectModelBloc, SelectModelState>(
        builder: (context, state) {
          if (state.selectedModel == null) {
            return const SizedBox.shrink();
          }
          return AppFlowyPopover(
            offset: Offset(-12.0, 0.0),
            constraints: BoxConstraints(maxWidth: 250, maxHeight: 600),
            direction: PopoverDirection.topWithLeftAligned,
            margin: EdgeInsets.zero,
            controller: popoverController,
            popupBuilder: (popoverContext) {
              return SelectModelPopoverContent(
                models: state.models,
                selectedModel: state.selectedModel,
                onSelectModel: (model) {
                  if (model != state.selectedModel) {
                    context
                        .read<SelectModelBloc>()
                        .add(SelectModelEvent.selectModel(model));
                  }
                  popoverController.close();
                },
              );
            },
            child: _CurrentModelButton(
              model: state.selectedModel!,
              onTap: () => popoverController.show(),
            ),
          );
        },
      ),
    );
  }
}

class SelectModelPopoverContent extends StatelessWidget {
  const SelectModelPopoverContent({
    super.key,
    required this.models,
    required this.selectedModel,
    this.onSelectModel,
  });

  final List<AIModelPB> models;
  final AIModelPB? selectedModel;
  final void Function(AIModelPB)? onSelectModel;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return const SizedBox.shrink();
    }

    // separate models into local and cloud models
    final localModels = models.where((model) => model.isLocal).toList();
    final cloudModels = models.where((model) => !model.isLocal).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (localModels.isNotEmpty) ...[
            _ModelSectionHeader(
              title: LocaleKeys.chat_switchModel_localModel.tr(),
            ),
            const VSpace(4.0),
          ],
          ...localModels.map(
            (model) => _ModelItem(
              model: model,
              isSelected: model == selectedModel,
              onTap: () => onSelectModel?.call(model),
            ),
          ),
          if (cloudModels.isNotEmpty && localModels.isNotEmpty) ...[
            const VSpace(8.0),
            _ModelSectionHeader(
              title: LocaleKeys.chat_switchModel_cloudModel.tr(),
            ),
            const VSpace(4.0),
          ],
          ...cloudModels.map(
            (model) => _ModelItem(
              model: model,
              isSelected: model == selectedModel,
              onTap: () => onSelectModel?.call(model),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelSectionHeader extends StatelessWidget {
  const _ModelSectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: FlowyText(
        title,
        fontSize: 12,
        figmaLineHeight: 16,
        color: Theme.of(context).hintColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ModelItem extends StatelessWidget {
  const _ModelItem({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  final AIModelPB model;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: FlowyButton(
        onTap: onTap,
        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        text: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText(
              model.i18n,
              figmaLineHeight: 20,
              overflow: TextOverflow.ellipsis,
            ),
            if (model.desc.isNotEmpty)
              FlowyText(
                model.desc,
                fontSize: 12,
                figmaLineHeight: 16,
                color: Theme.of(context).hintColor,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        rightIcon: isSelected
            ? FlowySvg(
                FlowySvgs.check_s,
                size: const Size.square(20),
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
    );
  }
}

class _CurrentModelButton extends StatelessWidget {
  const _CurrentModelButton({
    required this.model,
    required this.onTap,
  });

  final AIModelPB model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.chat_switchModel_label.tr(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: DesktopAIPromptSizes.actionBarButtonSize,
          child: FlowyHover(
            style: const HoverStyle(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(4.0),
              child: Row(
                children: [
                  Padding(
                    // TODO: remove this after change icon to 20px
                    padding: EdgeInsets.all(2),
                    child: FlowySvg(
                      FlowySvgs.ai_sparks_s,
                      color: Theme.of(context).hintColor,
                      size: Size.square(16),
                    ),
                  ),
                  if (!model.isDefault)
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 2.0),
                      child: FlowyText(
                        model.i18n,
                        fontSize: 12,
                        figmaLineHeight: 16,
                        color: Theme.of(context).hintColor,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  FlowySvg(
                    FlowySvgs.ai_source_drop_down_s,
                    color: Theme.of(context).hintColor,
                    size: const Size.square(8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
