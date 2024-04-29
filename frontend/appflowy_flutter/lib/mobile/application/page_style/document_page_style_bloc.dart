import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
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
          initial: () async {
            try {
              final layoutObject =
                  await ViewBackendService.getView(view.id).fold(
                (s) => jsonDecode(s.extra),
                (f) => {},
              );
              final fontLayout = _getSelectedFontLayout(layoutObject);
              final lineHeightLayout = _getSelectedLineHeightLayout(
                layoutObject,
              );
              final fontFamily = _getSelectedFontFamily(layoutObject);
              final cover = _getSelectedCover(layoutObject);
              final coverType = cover.$1;
              final coverValue = cover.$2;
              emit(
                state.copyWith(
                  fontLayout: fontLayout,
                  fontFamily: fontFamily,
                  lineHeightLayout: lineHeightLayout,
                  coverImage: PageStyleCover(
                    type: coverType,
                    value: coverValue,
                  ),
                  iconPadding: calculateIconPadding(
                    fontLayout,
                    lineHeightLayout,
                  ),
                ),
              );
            } catch (e) {
              Log.error('Failed to decode layout object: $e');
            }
          },
          updateFont: (fontLayout) async {
            emit(
              state.copyWith(
                fontLayout: fontLayout,
                iconPadding: calculateIconPadding(
                  fontLayout,
                  state.lineHeightLayout,
                ),
              ),
            );

            unawaited(updateLayoutObject());
          },
          updateLineHeight: (lineHeightLayout) async {
            emit(
              state.copyWith(
                lineHeightLayout: lineHeightLayout,
                iconPadding: calculateIconPadding(
                  state.fontLayout,
                  lineHeightLayout,
                ),
              ),
            );

            unawaited(updateLayoutObject());
          },
          updateFontFamily: (fontFamily) async {
            emit(
              state.copyWith(
                fontFamily: fontFamily,
              ),
            );

            unawaited(updateLayoutObject());
          },
          updateCoverImage: (coverImage) async {
            emit(
              state.copyWith(
                coverImage: coverImage,
              ),
            );

            unawaited(updateLayoutObject());
          },
        );
      },
    );
  }

  final ViewPB view;
  final ViewBackendService viewBackendService = ViewBackendService();

  Future<void> updateLayoutObject() async {
    final layoutObject = decodeLayoutObject();
    if (layoutObject != null) {
      await ViewBackendService.updateView(
        viewId: view.id,
        extra: layoutObject,
      );
    }
  }

  String? decodeLayoutObject() {
    Map oldValue = {};
    try {
      final extra = view.extra;
      oldValue = jsonDecode(extra);
    } catch (e) {
      Log.error('Failed to decode layout object: $e');
    }
    final newValue = {
      ViewExtKeys.fontLayoutKey: state.fontLayout.toString(),
      ViewExtKeys.lineHeightLayoutKey: state.lineHeightLayout.toString(),
      ViewExtKeys.coverKey: {
        ViewExtKeys.coverTypeKey: state.coverImage.type.toString(),
        ViewExtKeys.coverValueKey: state.coverImage.value,
      },
      ViewExtKeys.fontKey: state.fontFamily,
    };
    final merged = mergeMaps(oldValue, newValue);
    return jsonEncode(merged);
  }

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

  PageStyleFontLayout _getSelectedFontLayout(Map layoutObject) {
    final fontLayout = layoutObject[ViewExtKeys.fontLayoutKey] ??
        PageStyleFontLayout.normal.toString();
    return PageStyleFontLayout.values.firstWhere(
      (e) => e.toString() == fontLayout,
    );
  }

  PageStyleLineHeightLayout _getSelectedLineHeightLayout(Map layoutObject) {
    final lineHeightLayout = layoutObject[ViewExtKeys.lineHeightLayoutKey] ??
        PageStyleLineHeightLayout.normal.toString();
    return PageStyleLineHeightLayout.values.firstWhere(
      (e) => e.toString() == lineHeightLayout,
    );
  }

  String _getSelectedFontFamily(Map layoutObject) {
    return layoutObject[ViewExtKeys.fontKey] ?? builtInFontFamily();
  }

  (PageStyleCoverImageType, String colorValue) _getSelectedCover(
    Map layoutObject,
  ) {
    final cover = layoutObject[ViewExtKeys.coverKey] ?? {};
    final coverType = cover[ViewExtKeys.coverTypeKey] ??
        PageStyleCoverImageType.none.toString();
    final coverValue = cover[ViewExtKeys.coverValueKey] ?? '';
    return (
      PageStyleCoverImageType.values.firstWhere(
        (e) => e.toString() == coverType,
      ),
      coverValue,
    );
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
    PageStyleCover coverImage,
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
    required PageStyleCover coverImage,
  }) = _DocumentPageStyleState;

  factory DocumentPageStyleState.initial() => DocumentPageStyleState(
        coverImage: PageStyleCover.none(),
      );
}

enum PageStyleFontLayout {
  small,
  normal,
  large;

  @override
  String toString() {
    switch (this) {
      case PageStyleFontLayout.small:
        return 'small';
      case PageStyleFontLayout.normal:
        return 'normal';
      case PageStyleFontLayout.large:
        return 'large';
    }
  }

  static PageStyleFontLayout fromString(String value) {
    return PageStyleFontLayout.values.firstWhereOrNull(
          (e) => e.toString() == value,
        ) ??
        PageStyleFontLayout.normal;
  }

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

  @override
  String toString() {
    switch (this) {
      case PageStyleLineHeightLayout.small:
        return 'small';
      case PageStyleLineHeightLayout.normal:
        return 'normal';
      case PageStyleLineHeightLayout.large:
        return 'large';
    }
  }

  static PageStyleLineHeightLayout fromString(String value) {
    return PageStyleLineHeightLayout.values.firstWhereOrNull(
          (e) => e.toString() == value,
        ) ??
        PageStyleLineHeightLayout.normal;
  }

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

// for the version above 0.5.5
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
  // local image
  localImage,
  // unsplash images
  unsplashImage;

  @override
  String toString() {
    switch (this) {
      case PageStyleCoverImageType.none:
        return 'none';
      case PageStyleCoverImageType.pureColor:
        return 'color';
      case PageStyleCoverImageType.gradientColor:
        return 'gradient';
      case PageStyleCoverImageType.builtInImage:
        return 'built_in';
      case PageStyleCoverImageType.customImage:
        return 'custom';
      case PageStyleCoverImageType.localImage:
        return 'local';
      case PageStyleCoverImageType.unsplashImage:
        return 'unsplash';
    }
  }

  static PageStyleCoverImageType fromString(String value) {
    return PageStyleCoverImageType.values.firstWhereOrNull(
          (e) => e.toString() == value,
        ) ??
        PageStyleCoverImageType.none;
  }

  static String builtInImagePath(String value) {
    return 'assets/images/built_in_cover_images/m_cover_image_$value.png';
  }
}

class PageStyleCover {
  const PageStyleCover({
    required this.type,
    required this.value,
  });

  factory PageStyleCover.none() => const PageStyleCover(
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
  bool get isPhoto => isCustomImage || isLocalImage;

  bool get isNone => type == PageStyleCoverImageType.none;
  bool get isPureColor => type == PageStyleCoverImageType.pureColor;
  bool get isGradient => type == PageStyleCoverImageType.gradientColor;
  bool get isBuiltInImage => type == PageStyleCoverImageType.builtInImage;
  bool get isCustomImage => type == PageStyleCoverImageType.customImage;
  bool get isUnsplashImage => type == PageStyleCoverImageType.unsplashImage;
  bool get isLocalImage => type == PageStyleCoverImageType.localImage;
}
