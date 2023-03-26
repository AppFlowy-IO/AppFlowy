import 'dart:io';

import 'package:appflowy/plugins/document/presentation/plugins/cover/change_cover_popover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'change_cover_popover_bloc.freezed.dart';

class ChangeCoverPopoverBloc
    extends Bloc<ChangeCoverPopoverEvent, ChangeCoverPopoverState> {
  ChangeCoverPopoverBloc() : super(const ChangeCoverPopoverState.initial()) {
    on<ChangeCoverPopoverEvent>((event, emit) async {
      await event.map(
        fetchPickedImagePaths:
            (FetchPickedImagePaths fetchPickedImagePaths) async {
          final imageNames = await _getPreviouslyPickedImagePaths();
          emit(ChangeCoverPopoverState.loaded(imageNames));
        },
        deleteImage: (DeleteImage deleteImage) async {
          final currentState = state;
          if (currentState is Loaded) {
            await _deleteImageInStorage(deleteImage.path);
            final updateImageList = currentState.imageNames
                .where((path) => path != deleteImage.path)
                .toList();
            await _updateImagePathsInStorage(updateImageList);
            emit(Loaded(updateImageList));
          }
        },
        clearAllImages: (ClearAllImages clearAllImages) async {
          final currentState = state;
          if (currentState is Loaded) {
            for (final image in currentState.imageNames) {
              await _deleteImageInStorage(image);
            }
            await _updateImagePathsInStorage([]);
            emit(const Loaded([]));
          }
        },
      );
    });
  }

  Future<List<String>> _getPreviouslyPickedImagePaths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final imageNames = prefs.getStringList(kLocalImagesKey) ?? [];
    final removeNames = [];
    for (final name in imageNames) {
      if (!File(name).existsSync()) {
        removeNames.add(name);
      }
    }
    imageNames.removeWhere((element) => removeNames.contains(element));
    prefs.setStringList(kLocalImagesKey, imageNames);
    return imageNames;
  }

  Future<void> _updateImagePathsInStorage(List<String> imagePaths) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(kLocalImagesKey, imagePaths);
    return;
  }

  Future<void> _deleteImageInStorage(String path) async {
    final imageFile = File(path);
    await imageFile.delete();
  }
}

@freezed
class ChangeCoverPopoverEvent with _$ChangeCoverPopoverEvent {
  const factory ChangeCoverPopoverEvent.fetchPickedImagePaths() =
      FetchPickedImagePaths;

  const factory ChangeCoverPopoverEvent.deleteImage(String path) = DeleteImage;
  const factory ChangeCoverPopoverEvent.clearAllImages() = ClearAllImages;
}

@freezed
class ChangeCoverPopoverState with _$ChangeCoverPopoverState {
  const factory ChangeCoverPopoverState.initial() = Initial;
  const factory ChangeCoverPopoverState.loading() = Loading;
  const factory ChangeCoverPopoverState.loaded(
    List<String> imageNames,
  ) = Loaded;
}
