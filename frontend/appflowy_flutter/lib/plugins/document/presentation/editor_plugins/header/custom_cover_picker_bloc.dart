import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'cover_editor.dart';

part 'custom_cover_picker_bloc.freezed.dart';

class CoverImagePickerBloc
    extends Bloc<CoverImagePickerEvent, CoverImagePickerState> {
  CoverImagePickerBloc() : super(const CoverImagePickerState.initial()) {
    _dispatch();
  }

  static const allowedExtensions = ['jpg', 'png', 'jpeg'];

  void _dispatch() {
    on<CoverImagePickerEvent>(
      (event, emit) async {
        await event.map(
          initialEvent: (InitialEvent initialEvent) {
            emit(const CoverImagePickerState.initial());
          },
          urlSubmit: (UrlSubmit urlSubmit) async {
            emit(const CoverImagePickerState.loading());
            final validateImage = await _validateURL(urlSubmit.path);
            if (validateImage) {
              emit(
                CoverImagePickerState.networkImage(
                  FlowyResult.success(urlSubmit.path),
                ),
              );
            } else {
              emit(
                CoverImagePickerState.networkImage(
                  FlowyResult.failure(
                    FlowyError(
                      msg: LocaleKeys.document_plugins_cover_couldNotFetchImage
                          .tr(),
                    ),
                  ),
                ),
              );
            }
          },
          pickFileImage: (PickFileImage pickFileImage) async {
            final imagePickerResults = await _pickImages();
            if (imagePickerResults != null) {
              emit(CoverImagePickerState.fileImage(imagePickerResults));
            } else {
              emit(const CoverImagePickerState.initial());
            }
          },
          deleteImage: (DeleteImage deleteImage) {
            emit(const CoverImagePickerState.initial());
          },
          saveToGallery: (SaveToGallery saveToGallery) async {
            emit(const CoverImagePickerState.loading());
            final saveImage = await _saveToGallery(saveToGallery.previousState);
            if (saveImage != null) {
              emit(CoverImagePickerState.done(FlowyResult.success(saveImage)));
            } else {
              emit(
                CoverImagePickerState.done(
                  FlowyResult.failure(
                    FlowyError(
                      msg: LocaleKeys.document_plugins_cover_imageSavingFailed
                          .tr(),
                    ),
                  ),
                ),
              );
              emit(const CoverImagePickerState.initial());
            }
          },
        );
      },
    );
  }

  Future<List<String>?>? _saveToGallery(CoverImagePickerState state) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> imagePaths = prefs.getStringList(kLocalImagesKey) ?? [];
    final directory = await _coverPath();

    if (state is FileImagePicked) {
      try {
        final path = state.path;
        final newPath = p.join(directory, p.split(path).last);
        final newFile = await File(path).copy(newPath);
        imagePaths.add(newFile.path);
      } catch (e) {
        return null;
      }
    } else if (state is NetworkImagePicked) {
      try {
        final url = state.successOrFail.fold((path) => path, (r) => null);
        if (url != null) {
          final response = await http.get(Uri.parse(url));
          final newPath = p.join(directory, _networkImageName(url));
          final imageFile = File(newPath);
          await imageFile.create();
          await imageFile.writeAsBytes(response.bodyBytes);
          imagePaths.add(imageFile.absolute.path);
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    }
    await prefs.setStringList(kLocalImagesKey, imagePaths);
    return imagePaths;
  }

  Future<String?> _pickImages() async {
    final result = await getIt<FilePickerService>().pickFiles(
      dialogTitle: LocaleKeys.document_plugins_cover_addLocalImage.tr(),
      type: FileType.image,
      allowedExtensions: allowedExtensions,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.first.path;
    }
    return null;
  }

  Future<String> _coverPath() async {
    final directory = await getIt<ApplicationDataStorage>().getPath();
    return Directory(p.join(directory, 'covers'))
        .create(recursive: true)
        .then((value) => value.path);
  }

  String _networkImageName(String url) {
    return 'IMG_${DateTime.now().millisecondsSinceEpoch.toString()}.${_getExtension(
      url,
      fromNetwork: true,
    )}';
  }

  String? _getExtension(
    String path, {
    bool fromNetwork = false,
  }) {
    String? ext;
    if (!fromNetwork) {
      final extension = p.extension(path);
      if (extension.isEmpty) {
        return null;
      }
      ext = extension;
    } else {
      final uri = Uri.parse(path);
      final parameters = uri.queryParameters;
      if (path.contains('unsplash')) {
        final dl = parameters['dl'];
        if (dl != null) {
          ext = p.extension(dl);
        }
      } else {
        ext = p.extension(path);
      }
    }
    if (ext != null && ext.isNotEmpty) {
      ext = ext.substring(1);
    }
    if (allowedExtensions.contains(ext)) {
      return ext;
    }
    return null;
  }

  Future<bool> _validateURL(String path) async {
    final extension = _getExtension(path, fromNetwork: true);
    if (extension == null) {
      return false;
    }
    try {
      final response = await http.head(Uri.parse(path));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

@freezed
class CoverImagePickerEvent with _$CoverImagePickerEvent {
  const factory CoverImagePickerEvent.urlSubmit(String path) = UrlSubmit;
  const factory CoverImagePickerEvent.pickFileImage() = PickFileImage;
  const factory CoverImagePickerEvent.deleteImage() = DeleteImage;
  const factory CoverImagePickerEvent.saveToGallery(
    CoverImagePickerState previousState,
  ) = SaveToGallery;
  const factory CoverImagePickerEvent.initialEvent() = InitialEvent;
}

@freezed
class CoverImagePickerState with _$CoverImagePickerState {
  const factory CoverImagePickerState.initial() = Initial;
  const factory CoverImagePickerState.loading() = Loading;
  const factory CoverImagePickerState.networkImage(
    FlowyResult<String, FlowyError> successOrFail,
  ) = NetworkImagePicked;
  const factory CoverImagePickerState.fileImage(String path) = FileImagePicked;

  const factory CoverImagePickerState.done(
    FlowyResult<List<String>, FlowyError> successOrFail,
  ) = Done;
}
