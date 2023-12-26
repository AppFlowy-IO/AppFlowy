import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/application/template/config_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/database/database_view_block_component.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:archive/archive_io.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/workspace/application/settings/share/export_service.dart';
import 'package:appflowy/workspace/application/settings/share/import_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/import.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import 'package:flowy_infra/file_picker/file_picker_service.dart';

/// [TemplateService] Assists in importing/exporting template
/// Use [saveTemplate] to export template
/// Use [unloadTemplate] to import template

class TemplateService {
  Future<bool> saveTemplate(ViewPB view) async {
    final directory = await getApplicationDocumentsDirectory();

    // Delete the template folder if already exists
    final tempDir = Directory(path.join(directory.path, 'template'));
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }

    final configService = ConfigService();
    await configService.initConfig(view);
    final template = await configService.saveConfig();

    // Export parent view first and then continue with subviews
    await _exportDocumentAsJSON(view, template.documents);
    if (view.childViews.isNotEmpty) {
      await _getJsonFromView(view.childViews[0]);
    }
    await _exportTemplate(view, template.documents.childViews);

    // Zip all the files exported
    await archieveTemplateFiles();

    return true;
  }

  Future<void> archieveTemplateFiles() async {
    final encoder = ZipFileEncoder();

    final directory = await getApplicationDocumentsDirectory();
    encoder.create(path.join(directory.path, 'template.zip'));

    final dir = Directory(path.join(directory.path, 'template'));
    final files = dir.listSync(recursive: true);

    for (final file in files) {
      if (file is File) {
        final filePath = file.path;
        final fileName = path.basename(filePath);
        final fileContent = await file.readAsBytes();
        encoder.addArchiveFile(
          ArchiveFile(fileName, fileContent.length, fileContent),
        );
      }
    }
    encoder.close();
  }

  // Exports all the child views
  Future<void> _exportTemplate(
    ViewPB view,
    List<FlowyTemplateItem> childViews,
  ) async {
    final viewsAtId = await ViewBackendService.getChildViews(viewId: view.id);
    final List<ViewPB> views = viewsAtId.getLeftOrNull();

    for (int i = 0; i < views.length; i++) {
      final view = views[i];
      final item = childViews[i];

      final temp = await ViewBackendService.getChildViews(viewId: view.id);
      final viewsAtE = temp.getLeftOrNull();

      // If children are empty no need to continue
      if (viewsAtE.isEmpty) {
        await _exportView(view, item);
      } else {
        await _exportView(view, item);
        await _exportTemplate(view, item.childViews);
      }
    }
  }

  Future<void> _exportView(ViewPB view, FlowyTemplateItem item) async {
    switch (view.layout) {
      case ViewLayoutPB.Document:
        await _exportDocumentAsJSON(view, item);
        break;
      case ViewLayoutPB.Grid:
      case ViewLayoutPB.Board:
        await _exportDBFile(view, item.name);
        break;
      default:
      // Eventually support calender
    }
  }

  Future<void> _exportDocumentAsJSON(
    ViewPB view,
    FlowyTemplateItem item,
  ) async {
    final data = await _getJsonFromView(view);

    final document = json.decode(data);

    final List<dynamic> children = document["document"]["children"];

    if (item.databases.isNotEmpty) {
      // Replace the database view id's with the new view id's
      // Note: Databases are added from beginning of the document so we can read and replace in the same order.
      int dbLength = 0;
      for (int i = 0; i < children.length; i++) {
        if (dbLength >= item.databases.length) break;
        if (children[i]["type"] == ViewLayoutPB.Grid || children[i]["type"] == ViewLayoutPB.Board) {
          children[i]["data"]["view_id"] = item.databases[dbLength];
          dbLength++;
        }
      }
    }

    final directory = await getApplicationDocumentsDirectory();

    final dir = Directory(path.join(directory.path, 'template'));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    final file = File(
      path.join(directory.path, 'template', item.name),
    );
    await file.writeAsString(json.encode(document));
  }

  Future<String> _getJsonFromView(ViewPB view) async {
    final data = await DocumentExporter(view).export(DocumentExportType.json);
    final String? jsonData = data.fold((l) => null, (r) => r);

    return jsonData ?? "";
  }

  Future<void> _exportDBFile(ViewPB view, String name) async {
    final directory = await getApplicationDocumentsDirectory();

    final res = await BackendExportService.exportDatabaseAsCSV(view.id);
    final String? pb = res.fold((l) => l.data, (r) => null);

    if (pb == null) return;

    final dbFile = File(path.join(directory.path, 'template', name));
    await dbFile.writeAsString(pb);
  }

  // Stores the old id's and the updated ones to update the database references
  List<IdObj> updateValues = [];

  Future<Archive?> pickTemplate() async {
    // Pick a ZIP file from the system
    final result = await getIt<FilePickerService>().pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
    );

    // User cancelled the picker
    if (result == null || result.files.isEmpty) return null;

    // Extract the contents of the ZIP file
    final file = File(result.files.single.path!);

    final contents = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(contents);

    return archive;
  }

/*
Approach for importing template: 
1. First import all the databases, store the old and new view id's in a list. Because we need the database view id's to maintain the reference.
2. Next, start importing the documents and databases, when you come across a database, don't import it instead just move it to the desired location.
*/

  Future<void> unloadTemplate(
    String parentViewId,
    Archive? archive,
    EditorState editorState,
  ) async {
    if (archive == null) return;

    final directory = await getTemporaryDirectory();

    for (final file in archive) {
      final filename = '${directory.path}/${file.name}';
      final data = file.content as List<int>;
      final outputFile = File(filename);
      await outputFile.create();
      await outputFile.writeAsBytes(data);
    }

    Map<String, dynamic> config = {};
    try {
      config = json
          .decode(await File("${directory.path}/config.json").readAsString());
    } catch (e) {
      debugPrint(
        "An error occurred while adding the template! Did you have a config.json in your zip file?",
      );
      return;
    }

    final FlowyTemplate template = FlowyTemplate.fromJson(config);

    debugPrint("Loading Template:  ${template.templateName} into editor");

    final ViewPB? parentView = await _importDoc(
      parentViewId,
      template.documents,
      editorState,
    );

    if (parentView == null) {
      debugPrint("Error while importing the template");
      return;
    }

    updateValues.clear();
    await _loadDatabasesIntoEditor(parentView.id, template.documents);
    await _loadTemplateIntoEditor(
        parentView.id, template.documents, editorState);
  }

  // Import all db's in global scope first
  Future<Either<void, FlowyError>> _loadDatabasesIntoEditor(
    String parentViewId,
    FlowyTemplateItem item,
  ) async {
    for (final e in item.childViews) {
      // CASE: Database has no display view
      if (e.name.endsWith(".csv")) {
        if (e.childViews.isEmpty) {
          final view = await _importDB(parentViewId, e);
          if (view == null) {
            return right(FlowyError(
                msg:
                    "An error occured while loading databases into global scope"));
          }
          // Even though we don't need to update the database id in any document,
          // we still want to move it to right place later
          updateValues.add(
            IdObj(
              parentId: parentViewId,
              newViewId: view.id,
              oldViewId: e.name.replaceAll(".csv", ""),
            ),
          );
        } else {
          // Case: Database has display views which should import as references to parent
          final view = await _importDB(parentViewId, e);
          if (view == null) {
            return right(FlowyError(
                msg:
                    "An error occured while loading databases into global scope"));
          }

          updateValues.add(
            IdObj(
              parentId: parentViewId,
              newViewId: view.id,
              oldViewId: e.name.replaceAll(".csv", ""),
            ),
          );

          // Now add all child views as linked views to the database
          final databaseIdOrError =
              await DatabaseViewBackendService(viewId: view.id).getDatabaseId();

          final databaseId = databaseIdOrError.fold((l) => l, (r) => null);

          if (databaseId == null) {
            return right(
                FlowyError(msg: "An error occured while loading database ID"));
          }

          final prefix = _referencedDatabasePrefix(view.layout);

          for (int i = 0; i < e.childViews.length; i++) {
            final res = await ViewBackendService.createDatabaseLinkedView(
              parentViewId: view.id,
              databaseId: databaseId,
              layoutType: view.layout,
              name: '$prefix ${e.name.replaceAll(".csv", "")} ${i + 1}',
            );

            final linkedView = res.fold((l) => l, (r) => null);
            if (linkedView == null) {
              return right(FlowyError(
                  msg: "An error occured while loading database displays"));
            }
            updateValues.add(
              IdObj(
                parentId: view.id,
                newViewId: linkedView.id,
                oldViewId: e.childViews[i].name.replaceAll(".csv", ""),
              ),
            );
          }
        }
      }
      // CASE: where JSON Doc may have Database view
      if (e.childViews.isNotEmpty && !(e.name.endsWith(".csv"))) {
        await _loadDatabasesIntoEditor(parentViewId, e);
      }
    }
    return left(null);
  }

  /// Recursively adds the template into the editor
  Future<void> _loadTemplateIntoEditor(
    String parentViewId,
    FlowyTemplateItem doc,
    EditorState editorState,
  ) async {
    for (final e in doc.childViews) {
      if (e.childViews.isEmpty) {
        await _importTemplateFile(parentViewId, e, editorState);
        continue;
      } else {
        final ViewPB? res =
            await _importTemplateFile(parentViewId, e, editorState);
        if (res == null) {
          debugPrint("An error occured while loading template");
          return;
        }
        await _loadTemplateIntoEditor(res.id, e, editorState);
      }
    }
  }

  Future<ViewPB?> _importTemplateFile(
    String parentViewId,
    FlowyTemplateItem doc,
    EditorState editorState,
  ) async {
    if (doc.name.endsWith(".json")) {
      return _importDoc(parentViewId, doc, editorState);
    } else {
      // Already imported the databases,simply move to position now.
      return _moveDBToPosition(parentViewId, doc);
    }
  }

  Future<ViewPB?> _moveDBToPosition(
    String parentViewId,
    FlowyTemplateItem doc,
  ) async {
    final docName = doc.name.replaceAll(".csv", "");
    for (final e in updateValues) {
      if (docName == e.oldViewId) {
        await ViewBackendService.moveViewV2(
          viewId: e.newViewId,
          newParentId: parentViewId,
          prevViewId: e.parentId,
        );

        final view = await ViewBackendService.getView(e.newViewId);
        final res = view.fold((l) => l, (r) => null);
        return res;
      }
    }
    return null;
  }

  Future<ViewPB?> _importDoc(
    String parentViewId,
    FlowyTemplateItem doc,
    EditorState editorState,
  ) async {
    final directory = await getTemporaryDirectory();
    final templatePath = path.join(directory.path, doc.name);

    final String templateRes = await File(templatePath).readAsString();

    final Map<String, dynamic> docJson = json.decode(templateRes);

    final imagePaths = <String>[];
    for (final image in doc.images) {
      final res = await _importImage(image);
      if (res == null) continue;
      imagePaths.add(res);
    }

    // Replace the image paths in the document
    final List<dynamic> children = docJson["document"]["children"];
    for (int i = 0; i < children.length; i++) {
      if (children[i]["type"] == ImageBlockKeys.type) {
        children[i]["data"]["url"] = imagePaths.removeAt(0);
      }
    }

    docJson["document"]["children"] = children;

    final document = Document.fromJson(docJson);
    final docBytes =
        DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();

    final docName = doc.name.replaceAll('.json', '');

    // Import document first as we need the view to provide to [DocumentBloc]
    // to perform update operations on database references
    final res = await ImportBackendService.importData(
      docBytes!,
      docName,
      parentViewId,
      ImportTypePB.HistoryDocument,
    );

    final view = res.fold((l) => l, (r) => null);
    if (view == null) return null;
    _updateDoc(view);

    return res.fold((l) => l, (r) => null);
  }

  Future<void> _updateDoc(ViewPB view) async {
    final jsonFromView = await _getJsonFromView(view);

    final docBloc = DocumentBloc(view: view)
      ..add(const DocumentEvent.initial());

    StreamSubscription<DocumentState>? blocSubscription;

    blocSubscription = docBloc.stream.listen((event) {
      final docJson = json.decode(jsonFromView);
      final document2 = Document.fromJson(docJson);
      final List<Transaction> transactions = [];

      var doc = docBloc.state.editorState!.document.first;
      while (doc!.next != null) {
        if (doc.type == DatabaseBlockKeys.gridType ||
            doc.type == DatabaseBlockKeys.boardType) {
          final oldViewId = doc.attributes["view_id"];
          for (final e in updateValues) {
            if (e.oldViewId == oldViewId) {
              final attributes = {
                "view_id": e.newViewId,
                "parent_id": e.parentId,
              };
              final transaction = Transaction(document: document2)
                ..updateNode(
                  doc,
                  attributes,
                );

              transactions.add(transaction);
            }
          }
        }
        doc = doc.next;
      }

      final es = event.editorState;
      for (final transaction in transactions) {
        es!.apply(transaction);
      }

      if (blocSubscription != null) {
        blocSubscription.cancel();
      } else {
        debugPrint("Bloc subscription is null, may cause memory leaks!");
      }
    });
  }

  Future<String?> _importImage(String image) async {
    // 1. Get the image from the template folder
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, "template", image);
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();

    // 2. Copy the image to the AppFlowy images folder
    final appPath = await getIt<ApplicationDataStorage>().getPath();
    final newImagePath = path.join(
      appPath,
      'images',
    );
    try {
      // create the directory if not exists
      final directory = Directory(newImagePath);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      final copyToPath = path.join(
        newImagePath,
        image,
      );
      await File(copyToPath).writeAsBytes(imageBytes);
      return copyToPath;
    } catch (e) {
      debugPrint('An Error Occured while copying the image');
      return null;
    }
  }

  Future<ViewPB?> _importDB(String parentViewId, FlowyTemplateItem db) async {
    final directory = await getTemporaryDirectory();

    final dbRes = await File('${directory.path}/${db.name}').readAsString();

    final res = await ImportBackendService.importData(
      utf8.encode(dbRes),
      db.name.replaceAll(".csv", ""),
      parentViewId,
      ImportTypePB.CSV,
    );

    return res.fold((l) => l, (r) => null);
  }

  String _referencedDatabasePrefix(ViewLayoutPB layout) {
    switch (layout) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.grid_referencedGridPrefix.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.board_referencedBoardPrefix.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.calendar_referencedCalendarPrefix.tr();
      default:
        throw UnimplementedError();
    }
  }

}

class IdObj {
  String parentId;
  String newViewId;
  String oldViewId;
  IdObj(
      {required this.parentId,
      required this.newViewId,
      required this.oldViewId});
}
