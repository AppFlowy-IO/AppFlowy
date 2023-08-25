import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/document/application/template/config_service.dart';
import 'package:flutter/material.dart';

import 'package:archive/archive.dart';
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
   Future<void> saveTemplate(EditorState editorState, ViewPB view) async {
    final configService = ConfigService();
    await configService.initConfig(view);
    await configService.saveConfig();

    // Export parent view first and then continue with subviews
    await _exportDocumentAsJSON(view);
    _exportTemplate(view);
  }

  // Exports all the child views
  Future<void> _exportTemplate(ViewPB view) async {
    final viewsAtId = await ViewBackendService.getChildViews(viewId: view.id);
    final List<ViewPB> views = viewsAtId.getLeftOrNull();

    if (views.isEmpty) return;

    for (final e in views) {
      final temp = await ViewBackendService.getChildViews(viewId: e.id);
      final viewsAtE = temp.getLeftOrNull();

      // If children are empty no need to continue
      if (viewsAtE.isEmpty) {
        await _exportView(e);
      } else {
        await _exportView(e);
        await _exportTemplate(e);
      }
    }
  }

  Future<void> _exportView(ViewPB view) async {
    switch (view.layout) {
      case ViewLayoutPB.Document:
        await _exportDocumentAsJSON(view);
        break;
      case ViewLayoutPB.Grid:
      case ViewLayoutPB.Board:
        await _exportDBFile(view);
        break;
      default:
      // Eventually support calender
    }
  }

  Future<void> _exportDocumentAsJSON(ViewPB view) async {
    final data = await _getJsonFromView(view);
    final directory = await getApplicationDocumentsDirectory();

    final dir = Directory(path.join(directory.path, 'template'));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    //TODO: Optionally remove pre-existing template folder

    final file = File(
      path.join(directory.path, 'template', "${view.name}.json"),
    );

    await file.writeAsString(data);
  }

  Future<String> _getJsonFromView(ViewPB view) async {
    final data = await DocumentExporter(view).export(DocumentExportType.json);
    final String? jsonData = data.fold((l) => null, (r) => r);

    return jsonData ?? "";
  }

  Future<void> _exportDBFile(ViewPB view) async {
    final directory = await getApplicationDocumentsDirectory();

    final res = await BackendExportService.exportDatabaseAsCSV(view.id);
    final String? pb = res.fold((l) => l.data, (r) => null);

    if (pb == null) return;

    final dbFile = File('${directory.path}/template/${view.name}.csv');
    await dbFile.writeAsString(pb);
  }

  /// Steps for importing a template:
  /// 1. Pick template(.zip)
  /// 2. Zip may contain several files, use [config.json] to determine which files to use.
  /// 3. Load template into editor, using [TemplateService.unloadTemplate] function

  Future<Archive?> pickTemplate() async {
    // Pick a ZIP file from the system
    final result = await getIt<FilePickerService>().pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
    );

    // User cancelled the picker
    if (result == null) return null;

    // Extract the contents of the ZIP file
    final file = File(result.files.single.path!);

    final contents = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(contents);

    return archive;
  }

  Future<void> unloadTemplate(
    String parentViewId,
    Archive? archive,
  ) async {
    if (archive == null) return;

    final directory = await getTemporaryDirectory();

    for (final file in archive) {
      final filename = '${directory.path}/${file.name}';
      final data = file.content as List<int>;
      final outputFile = File(filename);
      await outputFile.create(recursive: true);
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
    );

    if (parentView == null) {
      debugPrint("Error while importing the template");
      return;
    }

    await _loadTemplate(parentView.id, template.documents);
  }

  /// Recursively adds the template into the editor
  Future<void> _loadTemplate(
    String parentViewId,
    FlowyTemplateItem doc,
  ) async {
    for (final e in doc.childViews) {
      if (e.childViews.isEmpty) {
        await _importTemplateFile(parentViewId, e);
        continue;
      } else {
        final ViewPB? res = await _importTemplateFile(parentViewId, e);
        if (res == null) {
          debugPrint("An error occured while loading template");
          return;
        }
        await _loadTemplate(res.id, e);
      }
    }
  }

  Future<ViewPB?> _importTemplateFile(
    String parentViewId,
    FlowyTemplateItem doc,
  ) {
    if (doc.name.endsWith(".json")) {
      return _importDoc(parentViewId, doc);
    } else {
      return _importDB(parentViewId, doc);
    }
  }

  Future<ViewPB?> _importDoc(String parentViewId, FlowyTemplateItem doc) async {
    final directory = await getTemporaryDirectory();

    final String templateRes =
        await File('${directory.path}/${doc.name}').readAsString();

    final Map<String, dynamic> docJson = json.decode(templateRes);
    final document = Document.fromJson(docJson);

    final docBytes =
        DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();

    final docName = doc.name.replaceAll('.json', '');

    final res = await ImportBackendService.importData(
      docBytes!,
      docName,
      parentViewId,
      ImportTypePB.HistoryDocument,
    );

    return res.fold((l) => l, (r) => null);
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
}
