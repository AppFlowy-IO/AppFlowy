import 'dart:math';

import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_page_style_bloc.freezed.dart';

class DocumentPageStyleBloc
    extends Bloc<DocumentPageStyleEvent, DocumentPageStyleState> {
  DocumentPageStyleBloc({
    required this.view,
  }) : super(DocumentPageStyleState.initial()) {
    on<DocumentPageStyleEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {},
          updateFont: (fontLayout) {
            emit(
              state.copyWith(
                fontLayout: fontLayout,
                iconPadding: calculateIconPadding(
                  fontLayout,
                  state.lineHeightLayout,
                ),
              ),
            );
          },
          updateLineHeight: (lineHeightLayout) {
            emit(
              state.copyWith(
                lineHeightLayout: lineHeightLayout,
                iconPadding: calculateIconPadding(
                  state.fontLayout,
                  lineHeightLayout,
                ),
              ),
            );
          },
          updateFontFamily: (fontFamily) {
            emit(
              state.copyWith(
                fontFamily: fontFamily,
              ),
            );
          },
        );
      },
    );
  }

  final ViewPB view;

  // because the line height can not be calculated accurately,
  //  we need to adjust the icon padding manually.
  double calculateIconPadding(
    PageStyleFontLayout fontLayout,
    PageStyleLineHeightLayout lineHeightLayout,
  ) {
    double padding = switch (fontLayout) {
      PageStyleFontLayout.small => 1.0,
      PageStyleFontLayout.normal => 2.0,
      PageStyleFontLayout.large => 4.0,
    };
    switch (lineHeightLayout) {
      case PageStyleLineHeightLayout.small:
        padding -= 1.0;
        break;
      case PageStyleLineHeightLayout.normal:
        break;
      case PageStyleLineHeightLayout.large:
        padding += 3.0;
        break;
    }
    return max(0, padding);
  }
}

@freezed
class DocumentPageStyleEvent with _$DocumentPageStyleEvent {
  const factory DocumentPageStyleEvent.initial() = Initial;
  const factory DocumentPageStyleEvent.updateFont(
    PageStyleFontLayout fontLayout,
  ) = UpdateFontSize;
  const factory DocumentPageStyleEvent.updateLineHeight(
    PageStyleLineHeightLayout lineHeightLayout,
  ) = UpdateLineHeight;
  const factory DocumentPageStyleEvent.updateFontFamily(
    String? fontFamily,
  ) = UpdateFontFamily;
}

@freezed
class DocumentPageStyleState with _$DocumentPageStyleState {
  const factory DocumentPageStyleState({
    @Default(PageStyleFontLayout.normal) PageStyleFontLayout fontLayout,
    @Default(PageStyleLineHeightLayout.normal)
    PageStyleLineHeightLayout lineHeightLayout,
    // the default font family is null, which means the system font
    @Default(null) String? fontFamily,
    @Default(2.0) double iconPadding,
  }) = _DocumentPageStyleState;

  factory DocumentPageStyleState.initial() => const DocumentPageStyleState();
}

enum PageStyleFontLayout {
  small,
  normal,
  large;

  double get fontSize {
    switch (this) {
      case PageStyleFontLayout.small:
        return 14.0;
      case PageStyleFontLayout.normal:
        return 16.0;
      case PageStyleFontLayout.large:
        return 18.0;
    }
  }

  List<double> get headingFontSizes {
    switch (this) {
      case PageStyleFontLayout.small:
        return [22.0, 18.0, 16.0, 16.0, 16.0, 16.0];
      case PageStyleFontLayout.normal:
        return [24.0, 20.0, 18.0, 18.0, 18.0, 18.0];
      case PageStyleFontLayout.large:
        return [26.0, 22.0, 20.0, 20.0, 20.0, 20.0];
    }
  }

  double get factor {
    switch (this) {
      case PageStyleFontLayout.small:
        return PageStyleFontLayout.small.fontSize /
            PageStyleFontLayout.normal.fontSize;
      case PageStyleFontLayout.normal:
        return 1.0;
      case PageStyleFontLayout.large:
        return PageStyleFontLayout.large.fontSize /
            PageStyleFontLayout.normal.fontSize;
    }
  }
}

enum PageStyleLineHeightLayout {
  small,
  normal,
  large;

  double get lineHeight {
    switch (this) {
      case PageStyleLineHeightLayout.small:
        return 1.4;
      case PageStyleLineHeightLayout.normal:
        return 1.5;
      case PageStyleLineHeightLayout.large:
        return 1.75;
    }
  }

  double get padding {
    switch (this) {
      case PageStyleLineHeightLayout.small:
        return 6.0;
      case PageStyleLineHeightLayout.normal:
        return 8.0;
      case PageStyleLineHeightLayout.large:
        return 8.0;
    }
  }

  List<double> get headingPaddings {
    switch (this) {
      case PageStyleLineHeightLayout.small:
        return [26.0, 22.0, 20.0, 20.0, 20.0, 20.0];
      case PageStyleLineHeightLayout.normal:
        return [30.0, 24.0, 22.0, 22.0, 22.0, 22.0];
      case PageStyleLineHeightLayout.large:
        return [34.0, 28.0, 26.0, 26.0, 26.0, 26.0];
    }
  }
}
