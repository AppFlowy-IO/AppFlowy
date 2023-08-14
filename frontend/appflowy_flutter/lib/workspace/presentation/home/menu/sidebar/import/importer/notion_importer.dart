import 'dart:convert';
import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/import/import_type.dart';

import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:archive/archive_io.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../import_panel.dart';

class NotionImporter {
  NotionImporter({
    required this.parentViewId,
  });

  final String parentViewId;

  final markdownImageRegex = RegExp(r'^!\[[^\]]*\]\((.*?)\)');

  Future<void> importFromNotion(ImportFromNotionType type, String path) async {
    switch (type) {
      case ImportFromNotionType.markdownZip:
        await _importFromMarkdownZip(path);
        break;
    }
    return;
  }

  //For detailed explaination of working of this import feature - https://github.com/AppFlowy-IO/AppFlowy/pull/3146
  Future<void> _importFromMarkdownZip(String path) async {
    final zip = File(path);
    final bytes = await zip.readAsBytes();
    final unzipFiles = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? mainpage;
    final List<ArchiveFile> mainpageAssets = [];
    for (final element in unzipFiles) {
      if (element.isFile &&
          element.name.endsWith('.md') &&
          !element.name.contains("/")) {
        mainpage = element;
        unzipFiles.files.remove(element);
        break;
      }
    }
    if (mainpage == null) {
      return;
    }
    for (final element in unzipFiles) {
      if (element.isFile &&
          ['.png', '.jpg', '.jpeg'].contains(p.extension(element.name)) &&
          element.name.split('/').length - 1 == 1) {
        mainpageAssets.add(element);
      } else if (element.isFile &&
          ['.png', '.jpg', '.jpeg'].contains(p.extension(element.name))) {
        final List<String> segments = element.name.split('/');
        segments.removeAt(0);
        element.name = segments.join('/');
      }
    }
    for (final element in mainpageAssets) {
      unzipFiles.files.remove(element);
    }

    //first we are importing the main page
    final mainPageName = p.basenameWithoutExtension(mainpage.name);
    final markdownContents = utf8.decode(mainpage.content as Uint8List);
    final processedMarkdownFile = await _preProcessMarkdownFile(
      markdownContents,
      mainpageAssets,
    );
    final data = documentDataFrom(
      ImportType.markdownOrText,
      processedMarkdownFile,
    );
    final result = await ViewBackendService.createView(
      layoutType: ViewLayoutPB.Document,
      name: mainPageName,
      parentViewId: parentViewId,
      initialDataBytes: data,
    );
    //this map will store the name of the view as key and its viewID are value
    final Map<String, String> parentNameToId = {};
    String mainPageId;
    if (result.isLeft()) {
      mainPageId = result.getLeftOrNull()!.id;
    } else {
      return;
    }
    parentNameToId[mainPageName] = mainPageId;
    // now we will import the sub pages
    // Each iteration of the below while loops will be importing one level of
    // pages, like the main page and its assets would be consider level one then
    // if main page contains any subpages then those sub pages along with the
    // assets in those subpages will be considered level 2 and if any of those
    // subpages contains any subpage that would be level 3 and so on. But we
    // have already imported the main page this while loop wil start from level 
    // 2
    while (unzipFiles.isNotEmpty) {
      final List<ArchiveFile> files = [];
      final List<ArchiveFile> images = [];
      final List<ArchiveFile> folders = [];
      for (int i = 0; i < unzipFiles.length; i++) {
        if (unzipFiles[i].isFile &&
            ['.png', '.jpg', '.jpeg']
                .contains(p.extension(unzipFiles[i].name)) &&
            unzipFiles[i].name.split('/').length - 1 == 1) {
          images.add(unzipFiles[i]);
        } else if (unzipFiles[i].isFile &&
            ['.png', '.jpg', '.jpeg']
                .contains(p.extension(unzipFiles[i].name))) {
          final List<String> segments = unzipFiles[i].name.split('/');
          segments.removeAt(0);
          unzipFiles[i].name = segments.join('/');
        }
      }
      for (int i = 0; i < unzipFiles.length; i++) {
        if (unzipFiles[i].isFile &&
            unzipFiles[i].name.endsWith('.md') &&
            unzipFiles[i].name.split('/').length - 1 == 1) {
          final String parentName = unzipFiles[i].name.split('/')[0];
          final String? parentViewId = parentNameToId[parentName];
          if (parentViewId == null) {
            return;
          }
          final createdpageId =
              await _createPage(parentViewId, unzipFiles[i], images);
          if (createdpageId == null) {
            return;
          }
          final name = p.basenameWithoutExtension(unzipFiles[i].name);
          parentNameToId[name] = createdpageId;
          files.add(unzipFiles[i]);
        } else if (unzipFiles[i].isFile && unzipFiles[i].name.endsWith('.md')) {
          final List<String> segments = unzipFiles[i].name.split('/');
          segments.removeAt(0);
          unzipFiles[i].name = segments.join('/');
        } else if (!unzipFiles[i].isFile) {
          //folders are of no use so they are stored here and will be deleted
          //unzipfiles
          folders.add(unzipFiles[i]);
        }
      }
      if (files.isEmpty) {
        return;
      }
      for (final element in folders) {
        unzipFiles.files.remove(element);
      }
      for (final element in files) {
        unzipFiles.files.remove(element);
      }
      for (final element in images) {
        unzipFiles.files.remove(element);
      }
    }
  }

  Future<String?> _createPage(
    String parentViewId,
    ArchiveFile file,
    List<ArchiveFile> images,
  ) async {
    final name = p.basenameWithoutExtension(file.name);
    final markdownContents = utf8.decode(file.content as Uint8List);
    final processedMarkdownFile = await _preProcessMarkdownFile(
      markdownContents,
      images,
    );
    final data = documentDataFrom(
      ImportType.markdownOrText,
      processedMarkdownFile,
    );
    final result = await ViewBackendService.createView(
      layoutType: ViewLayoutPB.Document,
      name: name,
      parentViewId: parentViewId,
      initialDataBytes: data,
    );
    if (result.isLeft()) {
      return result.getLeftOrNull()!.id;
    }
    return null;
  }

  // we take all contents of a markdown file and pass it through
  // _preProcessMarkdownFile   function which returns us a string which is the
  // contents of the markdown file but with changes. The changes this function
  // performs are related to images .It will iterate through each line and if it
  // it finds something like ![name](path) this is how a image is represented in
  // markdown , we get this line if detected, we get the path from this.
  // This path is actually the file name of image from the above unzipfiles
  // so with the help of path we will get the image file and save it
  // locally and change the current path to the path where the image is saved
  // locally
  Future<String> _preProcessMarkdownFile(
    String markdown,
    Iterable<ArchiveFile> images,
  ) async {
    if (images.isEmpty) {
      return markdown;
    }

    final lines = markdown.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (line.isEmpty) {
        continue;
      }
      if (!markdownImageRegex.hasMatch(line.trim())) {
        result.add(line);
      } else {
        final imagePath = markdownImageRegex.firstMatch(line)?.group(1);
        if (imagePath == null) {
          result.add(line);
        } else {
          final image = images.firstWhereOrNull(
            (element) => element.name == Uri.decodeFull(imagePath),
          );
          if (image == null) {
            result.add(line);
          } else {
            final localPath = await _saveImage(
              image,
            );
            result.add(line.replaceFirst(imagePath, localPath));
          }
        }
      }
    }
    return result.join('\n');
  }

  Future<String> _saveImage(ArchiveFile image) async {
    final path = await getIt<ApplicationDataStorage>().getPath();
    final imagePath = p.join(path, 'images');
    final directory = Directory(imagePath);
    await directory.create(recursive: true);
    final copyToPath = p.join(imagePath, '${uuid()}${p.extension(image.name)}');
    await File(copyToPath).writeAsBytes(image.content as Uint8List);
    return copyToPath;
  }
}
