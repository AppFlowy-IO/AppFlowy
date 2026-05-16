import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/translate_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'translate_type_option_bloc.freezed.dart';

class TranslateTypeOptionBloc
    extends Bloc<TranslateTypeOptionEvent, TranslateTypeOptionState> {
  TranslateTypeOptionBloc({required TranslateTypeOptionPB option})
      : super(TranslateTypeOptionState.initial(option)) {
    on<TranslateTypeOptionEvent>(
      (event, emit) async {
        event.when(
          selectLanguage: (languageType) {
            emit(
              state.copyWith(
                option: _updateLanguage(languageType),
                language: languageTypeToLanguage(languageType),
              ),
            );
          },
        );
      },
    );
  }

  TranslateTypeOptionPB _updateLanguage(TranslateLanguagePB languageType) {
    state.option.freeze();
    return state.option.rebuild((option) {
      option.language = languageType;
    });
  }
}

@freezed
class TranslateTypeOptionEvent with _$TranslateTypeOptionEvent {
  const factory TranslateTypeOptionEvent.selectLanguage(
    TranslateLanguagePB languageType,
  ) = _SelectLanguage;
}

@freezed
class TranslateTypeOptionState with _$TranslateTypeOptionState {
  const factory TranslateTypeOptionState({
    required TranslateTypeOptionPB option,
    required String language,
  }) = _TranslateTypeOptionState;

  factory TranslateTypeOptionState.initial(TranslateTypeOptionPB option) =>
      TranslateTypeOptionState(
        option: option,
        language: languageTypeToLanguage(option.language),
      );
}

String languageTypeToLanguage(TranslateLanguagePB langaugeType) {
  switch (langaugeType) {
    case TranslateLanguagePB.SimplifiedChinese:
      return 'Simplified Chinese';
    case TranslateLanguagePB.TraditionalChinese:
      return 'Traditional Chinese';
    case TranslateLanguagePB.English:
      return 'English';
    case TranslateLanguagePB.French:
      return 'French';
    case TranslateLanguagePB.German:
      return 'German';
    case TranslateLanguagePB.Spanish:
      return 'Spanish';
    case TranslateLanguagePB.Hindi:
      return 'Hindi';
    case TranslateLanguagePB.Portuguese:
      return 'Portuguese';
    case TranslateLanguagePB.StandardArabic:
      return 'Standard Arabic';
    default:
      Log.error('Unknown language type: $langaugeType');
      return 'English';
  }
}
