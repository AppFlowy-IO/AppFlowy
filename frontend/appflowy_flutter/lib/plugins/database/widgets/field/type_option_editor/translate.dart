import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/translate_type_option_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './builder.dart';

class TranslateTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const TranslateTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) {
    final typeOption = TranslateTypeOptionPB.fromBuffer(field.typeOptionData);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText(
            LocaleKeys.grid_field_translateTo.tr(),
          ),
          const HSpace(6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: BlocProvider(
              create: (context) => TranslateTypeOptionBloc(option: typeOption),
              child: BlocConsumer<TranslateTypeOptionBloc,
                  TranslateTypeOptionState>(
                listenWhen: (previous, current) =>
                    previous.option != current.option,
                listener: (context, state) {
                  onTypeOptionUpdated(state.option.writeToBuffer());
                },
                builder: (context, state) {
                  return _wrapLanguageListPopover(
                    context,
                    state,
                    popoverMutex,
                    SelectLanguageButton(
                      language: state.language,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapLanguageListPopover(
    BuildContext blocContext,
    TranslateTypeOptionState state,
    PopoverMutex popoverMutex,
    Widget child,
  ) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (popoverContext) {
        return LanguageList(
          onSelected: (language) {
            blocContext
                .read<TranslateTypeOptionBloc>()
                .add(TranslateTypeOptionEvent.selectLanguage(language));
            PopoverContainer.of(popoverContext).close();
          },
          selectedLanguage: state.option.language,
        );
      },
      child: child,
    );
  }
}

class SelectLanguageButton extends StatelessWidget {
  const SelectLanguageButton({required this.language, super.key});
  final String language;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: FlowyButton(
        text: FlowyText(
          language,
          lineHeight: 1.0,
        ),
      ),
    );
  }
}

class LanguageList extends StatelessWidget {
  const LanguageList({
    super.key,
    required this.onSelected,
    required this.selectedLanguage,
  });

  final Function(TranslateLanguagePB) onSelected;
  final TranslateLanguagePB selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final cells = TranslateLanguagePB.values.map((languageType) {
      return LanguageCell(
        languageType: languageType,
        onSelected: onSelected,
        isSelected: languageType == selectedLanguage,
      );
    }).toList();

    return SizedBox(
      width: 180,
      child: ListView.separated(
        shrinkWrap: true,
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: cells.length,
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }
}

class LanguageCell extends StatelessWidget {
  const LanguageCell({
    required this.languageType,
    required this.onSelected,
    required this.isSelected,
    super.key,
  });
  final Function(TranslateLanguagePB) onSelected;
  final TranslateLanguagePB languageType;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = const FlowySvg(FlowySvgs.check_s);
    }

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText(
          languageTypeToLanguage(languageType),
          lineHeight: 1.0,
        ),
        rightIcon: checkmark,
        onTap: () => onSelected(languageType),
      ),
    );
  }
}
