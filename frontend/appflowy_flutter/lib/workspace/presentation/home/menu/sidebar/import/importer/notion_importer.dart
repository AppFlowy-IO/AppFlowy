import 'dart:convert';
import 'dart:io';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/import/import_type.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:archive/archive_io.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../import_panel.dart';

//PageToImport class has the details of the page to be imported
class PageToImport {
  PageToImport({
    required this.page,
    required this.parentName,
  });
  ArchiveFile page;
  String parentName;
}

//Level class hass all the details about a level of the imported pages
class Level {
  Level({
    required this.assetsAtThelevel,
    required this.pagesAtTheLevel,
  });
  List<ArchiveFile> assetsAtThelevel;
  List<PageToImport> pagesAtTheLevel;
}

class NotionImporter {
  NotionImporter({
    required this.parentViewId,
  });

  final String parentViewId;
  final markdownImageRegex = RegExp(r'^!\[[^\]]*\]\((.*?)\)');
  final fileRegex = RegExp(r'\[([^\]]*)\]\(([^\)]*)\)');

  Future<void> importFromNotion(ImportFromNotionType type, String path,
      CancelableCompleter completer) async {
    switch (type) {
      case ImportFromNotionType.markdownZip:
        await _importFromMarkdownZip(path, completer);
        break;
    }
    return;
  }

  //For detailed explaination of working of this import feature - https://github.com/AppFlowy-IO/AppFlowy/pull/3146
  Future<void> _importFromMarkdownZip(
      String path, CancelableCompleter completer) async {
    final zip = File(path);
    final bytes = await zip.readAsBytes();
    final files = ZipDecoder().decodeBytes(bytes);
    final List<ArchiveFile> unzipFiles = files.files.toList();
    final List<Level> levels = []; //list of all the levels of pages
    final Map<String, String> nameToId =
        {}; // this map store page name and viewID
    //first we are get the main page and all assets of the main page
    ArchiveFile? mainpage;
    final List<ArchiveFile> mainpageAssets = [];
    for (final element in unzipFiles) {
      if (element.isFile &&
          element.name.endsWith('.md') &&
          !element.name.contains("/")) {
        mainpage = element;
        unzipFiles.remove(element);
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
      unzipFiles.remove(element);
    }

    // now we store each level of pages inside levels list
    // The below while loop will iterate through all the unzipfiles and stores
    // them in levels list according to the level at which the file belong and
    // with the assets at that level.This mainly deals with the subpages of the
    // main page for example the main page can form level one and if it has a
    // subpage it can be level 2 and if that sub page also have a subpage then
    // that will belong to level 3
    while (unzipFiles.isNotEmpty) {
      final List<PageToImport> files = [];
      final List<ArchiveFile> images = [];
      final List<ArchiveFile> folders = [];
      final List<ArchiveFile> filesToRemove = [];
      // This for loop gets all the markdown files at a level
      for (int i = 0; i < unzipFiles.length; i++) {
        if (unzipFiles[i].isFile &&
            unzipFiles[i].name.endsWith('.md') &&
            unzipFiles[i].name.split('/').length - 1 == 1) {
          final String parentName = unzipFiles[i].name.split('/')[0];
          files.add(PageToImport(page: unzipFiles[i], parentName: parentName));
        } else if (unzipFiles[i].isFile && unzipFiles[i].name.endsWith('.md')) {
          final List<String> segments = unzipFiles[i].name.split('/');
          segments.removeAt(0);
          unzipFiles[i].name = segments.join('/');
        }
      }
      if (files.isEmpty) {
        continue;
      }
      // This for loop gets all the assets at a level
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
        } else if (!unzipFiles[i].isFile) {
          //folders are of no use so they are stored here and will be deleted
          //unzipfiles
          folders.add(unzipFiles[i]);
        } else if (unzipFiles[i].isFile &&
            ['.pdf', '.docx', '.doc', '.pptx', '.ppt', '.xlsx', '.xls']
                .contains(p.extension(unzipFiles[i].name))) {
          //handle case where there are fiels like pDF,docx etc whichare not currently supported
          filesToRemove.add(unzipFiles[i]);
        }
      }
      levels.add(Level(assetsAtThelevel: images, pagesAtTheLevel: files));
      // removing all the files that are already added in the levels list
      for (final element in files) {
        unzipFiles.remove(element.page);
      }
      for (final element in folders) {
        unzipFiles.remove(element);
      }
      for (final element in images) {
        unzipFiles.remove(element);
      }
      for (final element in filesToRemove) {
        unzipFiles.remove(element);
      }
    }
    final int noOfLevels = levels.length;
    // This for loop will iterate through the levels starting from the last level and import all the pages at that level
    for (int i = noOfLevels - 1; i >= 0; i--) {
      final level = levels[i];
      final filesAtLevel = level.pagesAtTheLevel;
      final imagesAtlevel = level.assetsAtThelevel;
      for (final file in filesAtLevel) {
        final name = p.basenameWithoutExtension(file.page.name);
        final String? pageID = await _createPage(
          false,
          parentViewId,
          file.page,
          imagesAtlevel,
          nameToId,
        );
        if (pageID == null) {
          return;
        }
        nameToId[name] = pageID;
        // await Future.delayed(Duration(seconds: 7));
        if (completer.isCanceled) {
          print('Import Cancelled');
          for (var i in nameToId.keys) {
            await ViewBackendService.deleteView(viewId: nameToId[i]!);
          }
          return;
        }
      }
    }
    // In the end we will import the main page after we have imported all the
    // subpages
    final mainPageName = p.basenameWithoutExtension(mainpage.name);

    final String? pageID = await _createPage(
      true,
      parentViewId,
      mainpage,
      mainpageAssets,
      nameToId,
    );
    if (pageID == null) {
      return;
    }
    nameToId[mainPageName] = pageID;
    // We have all the pages imported now we will move them under their
    // respective parent page
    for (int i = noOfLevels - 1; i >= 0; i--) {
      final level = levels[i];
      final filesAtLevel = level.pagesAtTheLevel;
      for (final file in filesAtLevel) {
        final name = p.basenameWithoutExtension(file.page.name);
        final viewId = nameToId[name];
        final parentName = file.parentName;
        final parentID = nameToId[parentName];
        await ViewBackendService.moveViewV2(
          viewId: viewId!,
          newParentId: parentID!,
          prevViewId: null,
        );
      }
    }
  }

  Future<String?> _createPage(
    bool isMainPage,
    String parentViewId,
    ArchiveFile file,
    List<ArchiveFile> images,
    Map<String, String> nameToID,
  ) async {
    String name = p.basenameWithoutExtension(file.name);
    final markdownContents = utf8.decode(file.content as Uint8List);
    final processedMarkdownFile = await _preProcessMarkdownFile(
      markdownContents,
      images,
      nameToID,
    );
    final data =  documentDataFrom(
      ImportType.markdownOrText,
      processedMarkdownFile,
    );
    
    if (isMainPage) {
      final result = await ViewBackendService.createView(
        layoutType: ViewLayoutPB.Document,
        name: name,
        parentViewId: parentViewId,
        initialDataBytes: data,
      );
      if (result.isSuccess) {
        return result.fold((s) => s, (f) => null)!.id;
      }
      return null;
    }
    print("Name of page is - $name");
    final id = name.replaceAll(' ', '_')+DateTime.now().millisecondsSinceEpoch.toString();
    final result = await ViewBackendService.createOrphanView(
      viewId: id,
      layoutType: ViewLayoutPB.Document,
      name: name,
      initialDataBytes: data,
    );
    print('Result of creating orphan view is ${result.fold((s) => s, (f) => null)!.info_}');
    // final result = await ViewBackendService.createView(
    //   layoutType: ViewLayoutPB.Document,
    //   name: name,
    //   parentViewId: parentViewId,
    //   initialDataBytes: data,
    // );
    if (result.isSuccess) {
      return result.fold((s) => s, (f) => null)!.id;
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
    Map<String, String> nameToID,
  ) async {
    final lines = markdown.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (line.isEmpty) {
        continue;
      }
      if (markdownImageRegex.hasMatch(line.trim())) {
        final imagePath = markdownImageRegex.firstMatch(line.trim())?.group(1);
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
      } else if (fileRegex.hasMatch(line)) {
        final String newLine = line.replaceAllMapped(fileRegex, (match) {
          final String decodedFilePath = Uri.decodeFull(match.group(2)!);
          if (!decodedFilePath.endsWith('.md')) {
            return match.group(0)!;
          }
          final subpageName = p.basenameWithoutExtension(decodedFilePath);
          final subPageID = nameToID[subpageName];
          if (subPageID == null) {
            return match.group(0)!;
          }

          return '{{AppFlowy-Subpage}}{$subpageName}{$subPageID}';
        });
        result.add(newLine);
      } else {
        result.add(line);
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
