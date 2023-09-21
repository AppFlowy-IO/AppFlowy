import 'dart:async';
import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/header/cover_editor.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/document_header_node_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cover_editor_bloc.freezed.dart';

class ChangeCoverPopoverBloc
    extends Bloc<ChangeCoverPopoverEvent, ChangeCoverPopoverState> {
  final EditorState editorState;
  final Node node;
  late final SharedPreferences _prefs;
  final _initCompleter = Completer<void>();

  ChangeCoverPopoverBloc({
    required this.editorState,
    required this.node,
  }) : super(const ChangeCoverPopoverState.initial()) {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      _initCompleter.complete();
    });

    on<ChangeCoverPopoverEvent>((event, emit) async {
      await event.map(
        fetchPickedImagePaths:
            (FetchPickedImagePaths fetchPickedImagePaths) async {
          final imageNames = await _getPreviouslyPickedImagePaths();

          emit(
            ChangeCoverPopoverState.loaded(
              imageNames,
              selectLatestImage: fetchPickedImagePaths.selectLatestImage,
            ),
          );
        },
        deleteImage: (DeleteImage deleteImage) async {
          final currentState = state;
          final currentlySelectedImage =
              node.attributes[DocumentHeaderBlockKeys.coverDetails];
          if (currentState is Loaded) {
            await _deleteImageInStorage(deleteImage.path);
            if (currentlySelectedImage == deleteImage.path) {
              _removeCoverImageFromNode();
            }
            final updateImageList = currentState.imageNames
                .where((path) => path != deleteImage.path)
                .toList();
            await _updateImagePathsInStorage(updateImageList);
            emit(Loaded(updateImageList));
          }
        },
        clearAllImages: (ClearAllImages clearAllImages) async {
          final currentState = state;
          final currentlySelectedImage =
              node.attributes[DocumentHeaderBlockKeys.coverDetails];

          if (currentState is Loaded) {
            for (final image in currentState.imageNames) {
              await _deleteImageInStorage(image);
              if (currentlySelectedImage == image) {
                _removeCoverImageFromNode();
              }
            }
            await _updateImagePathsInStorage([]);
            emit(const Loaded([]));
          }
        },
      );
    });
  }

  Future<List<String>> _getPreviouslyPickedImagePaths() async {
    await _initCompleter.future;
    final imageNames = _prefs.getStringList(kLocalImagesKey) ?? [];
    if (imageNames.isEmpty) {
      return imageNames;
    }
    imageNames.removeWhere((name) => !File(name).existsSync());
    _prefs.setStringList(kLocalImagesKey, imageNames);
    return imageNames;
  }

  Future<void> _updateImagePathsInStorage(List<String> imagePaths) async {
    await _initCompleter.future;
    _prefs.setStringList(kLocalImagesKey, imagePaths);
    return;
  }

  Future<void> _deleteImageInStorage(String path) async {
    final imageFile = File(path);
    await imageFile.delete();
  }

  Future<void> _removeCoverImageFromNode() async {
    final transaction = editorState.transaction;
    transaction.updateNode(node, {
      DocumentHeaderBlockKeys.coverType: CoverType.none.toString(),
      DocumentHeaderBlockKeys.icon:
          node.attributes[DocumentHeaderBlockKeys.icon]
    });
    return editorState.apply(transaction);
  }
}

@freezed
class ChangeCoverPopoverEvent with _$ChangeCoverPopoverEvent {
  const factory ChangeCoverPopoverEvent.fetchPickedImagePaths({
    @Default(false) bool selectLatestImage,
  }) = FetchPickedImagePaths;

  const factory ChangeCoverPopoverEvent.deleteImage(String path) = DeleteImage;
  const factory ChangeCoverPopoverEvent.clearAllImages() = ClearAllImages;
}

@freezed
class ChangeCoverPopoverState with _$ChangeCoverPopoverState {
  const factory ChangeCoverPopoverState.initial() = Initial;
  const factory ChangeCoverPopoverState.loading() = Loading;
  const factory ChangeCoverPopoverState.loaded(
    List<String> imageNames, {
    @Default(false) selectLatestImage,
  }) = Loaded;
}
