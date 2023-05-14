import 'dart:io';
import 'dart:math';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/plugins/cover/change_cover_popover.dart';

part 'cover_image_picker_bloc.freezed.dart';

class CoverImagePickerBloc
    extends Bloc<CoverImagePickerEvent, CoverImagePickerState> {
  CoverImagePickerBloc() : super(const CoverImagePickerState.initial()) {
    on<CoverImagePickerEvent>(
      (event, emit) async {
        await event.map(
          initialEvent: (InitialEvent initialEvent) {
            emit(const CoverImagePickerState.initial());
          },
          urlSubmit: (UrlSubmit urlSubmit) async {
            emit(const CoverImagePickerState.loading());
            final validateImage = await _validateUrl(urlSubmit.path);
            if (validateImage) {
              emit(CoverImagePickerState.networkImage(left(urlSubmit.path)));
            } else {
              emit(
                CoverImagePickerState.networkImage(
                  right(
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
              emit(CoverImagePickerState.done(left(saveImage)));
            } else {
              emit(
                CoverImagePickerState.done(
                  right(
                    FlowyError(
                      msg: LocaleKeys.document_plugins_cover_imageSavingFailed
                          .tr(),
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  _saveToGallery(CoverImagePickerState state) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> imagePaths = prefs.getStringList(kLocalImagesKey) ?? [];
    final directory = await _coverPath();

    if (state is FileImagePicked) {
      try {
        final path = state.path;
        imagePaths.add(path);
        await prefs.setStringList(kLocalImagesKey, imagePaths);
        return imagePaths;
      } catch (e) {
        return null;
      }
    } else if (state is NetworkImagePicked) {
      try {
        String? url;
        state.successOrFail.fold(
          (path) {
            url = path;
          },
          (r) => null,
        );
        final response = await http.get(Uri.parse(url!));

        final newPath =
            "$directory/IMG_${Random().nextInt(1000)}.${url!.contains('.png') ? 'png' : url!.contains('.jpeg') ? 'jpeg' : 'jpg'}";

        final imageFile = File(newPath);
        await imageFile.create();
        await imageFile.writeAsBytes(response.bodyBytes);
        imagePaths.add(imageFile.absolute.path);
        await prefs.setStringList(kLocalImagesKey, imagePaths);
        return imagePaths;
      } catch (e) {
        return null;
      }
    }
  }

  _pickImages() async {
    FilePickerResult? result = await getIt<FilePickerService>().pickFiles(
      dialogTitle: LocaleKeys.document_plugins_cover_addLocalImage.tr(),
      allowMultiple: false,
      type: fp.FileType.image,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        return path;
      } else {
        return null;
      }
    }
    return null;
  }

  Future<String> _coverPath() async {
    final directory = await getIt<SettingsLocationCubit>().fetchLocation();
    return Directory('$directory/covers')
        .create(recursive: true)
        .then((value) => value.path);
  }

  _validateUrl(String path) async {
    try {
      final response = await http.get(Uri.parse(path));
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = p.join(appDir.path, "${Random().nextInt(3000)}.jpg");
      final imageFile = File(localPath);
      await imageFile.create();
      await imageFile.writeAsBytes(response.bodyBytes);
      return imageFile.absolute.path;
    } catch (e) {
      return null;
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
    Either<String, FlowyError> successOrFail,
  ) = NetworkImagePicked;
  const factory CoverImagePickerState.fileImage(String path) = FileImagePicked;

  const factory CoverImagePickerState.done(
    Either<List<String>, FlowyError> successOrFail,
  ) = Done;
}
