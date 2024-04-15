import 'dart:math';

import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:flutter/material.dart';
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
          updateCoverImage: (coverImage) {
            emit(
              state.copyWith(
                coverImage: coverImage,
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
  const factory DocumentPageStyleEvent.updateCoverImage(
    PageStyleCoverImage coverImage,
  ) = UpdateCoverImage;
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
    required PageStyleCoverImage coverImage,
  }) = _DocumentPageStyleState;

  factory DocumentPageStyleState.initial() => DocumentPageStyleState(
        coverImage: PageStyleCoverImage.none(),
      );
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

enum PageStyleCoverImageType {
  none,
  // normal color
  pureColor,
  // gradient color
  gradientColor,
  // built in images
  builtInImage,
  // custom images, uploaded by the user
  customImage,
  // unsplash images
  unsplashImage,
}

class PageStyleCoverImage {
  const PageStyleCoverImage({
    required this.type,
    required this.value,
  });

  factory PageStyleCoverImage.none() => const PageStyleCoverImage(
        type: PageStyleCoverImageType.none,
        value: '',
      );

  final PageStyleCoverImageType type;

  // there're 4 types of values:
  // 1. pure color: enum value
  // 2. gradient color: enum value
  // 3. built-in image: the image name, read from the assets
  // 4. custom image or unsplash image: the image url
  final String value;

  bool get isPresets => isPureColor || isGradient || isBuiltInImage;
  bool get isNone => type == PageStyleCoverImageType.none;
  bool get isPureColor => type == PageStyleCoverImageType.pureColor;
  bool get isGradient => type == PageStyleCoverImageType.gradientColor;
  bool get isBuiltInImage => type == PageStyleCoverImageType.builtInImage;
  bool get isCustomImage => type == PageStyleCoverImageType.customImage;
  bool get isUnsplashImage => type == PageStyleCoverImageType.unsplashImage;

  Color? get valueAsColor {
    if (isPureColor) {
      return value.tryToColor();
    }

    throw ArgumentError('Invalid type');
  }

  LinearGradient? get valueAsGradient {
    // if (isGradient) {
    //   final parts = value.split(',').whereNotNull().toList();
    //   if (parts.length < 6) {
    //     Log.error('Invalid gradient color value: $value');
    //     return null;
    //   }
    //   final p1 = double.tryParse(parts[0]);
    //   final p2 = double.tryParse(parts[1]);
    //   final p3 = double.tryParse(parts[2]);
    //   final p4 = double.tryParse(parts[3]);
    //   if (p1 == null || p2 == null || p3 == null || p4 == null) {
    //     Log.error('Invalid gradient color value: $value');
    //     return null;
    //   }
    //   final start = Alignment(p1, p2);
    //   final end = Alignment(p3, p4);
    //   final colors =
    //       parts.skip(4).map((e) => e.tryToColor()).whereNotNull().toList();
    //   if (colors.isEmpty) {
    //     Log.error('Invalid gradient color value: $value');
    //     return null;
    //   }
    //   return LinearGradient(
    //     begin: start,
    //     end: end,
    //     colors: colors,
    //   );
    // }

    throw ArgumentError('Invalid type');
  }
}
