import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/workspace/application/settings/share/export_service.dart';
import 'package:appflowy/workspace/application/settings/share/import_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/import.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import 'package:flowy_infra/file_picker/file_picker_impl.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';

class TemplateService {
  Future<void> saveTemplate(EditorState editorState) async {
    final directory = await getApplicationDocumentsDirectory();

    final dir = Directory(path.join(directory.path, 'template'));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    } else {
      // TODO: Show an alert dialog before overwriting the template
      for (final entity in dir.listSync()) {
        if (entity is File) {
          entity.deleteSync();
        } else if (entity is Directory) {
          entity.deleteSync(recursive: true);
        }
      }
    }

    final file = File('${directory.path}/template/template.json');

    await file.writeAsString(json.encode(editorState.document.toJson()));

    final Map<String, dynamic> jsonData = editorState.document.toJson();

    final List<Map<String, dynamic>> children =
        jsonData["document"]["children"];

    int count = 1;
    for (int i = 0; i < children.length; i++) {
      // TODO: add feat to add calendar
      if (children[i]["type"] == "grid" || children[i]["type"] == "board") {
        _exportDBFiles("db${count++}", children[i]["data"]["view_id"]);
      }
    }
  }

  Future<void> _exportDBFiles(String name, String viewId) async {
    final directory = await getApplicationDocumentsDirectory();

    final res = await BackendExportService.exportDatabaseAsCSV(viewId);
    final String? pb = res.fold((l) => l.data, (r) => null);

    if (pb == null) return;

    final dbFile = File('${directory.path}/template/$name.csv');
    await dbFile.writeAsString(pb);
  }

  /// Steps:
  /// 1. Pick template(.zip)
  /// 2. Zip may contain several files, use [config.json] to determine which files to use.
  /// 3. Load template into editor, using [TemplateService.unloadTemplate] function

  Future<Archive?> pickTemplate() async {
    // Pick a ZIP file from the system
    final result = await FilePicker().pickFiles(
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

    final config =
        json.decode(await File("${directory.path}/config.json").readAsString());

    final TemplateModel template = TemplateModel.fromJson(config);

    debugPrint("Loading Template:  ${template.templateName} into editor");

    for (final DocumentModel doc in template.documents) {
      _loadTemplate(parentViewId, doc);
    }
  }

  Future<void> _loadTemplate(String parentViewId, DocumentModel doc) async {
    final directory = await getTemporaryDirectory();

    /// Import all databases first

    final List<ViewPB> dbViews = [];

    for (final db in doc.db) {
      final res = await _importDB(db, parentViewId);
      if (res == null) {
        // Abort if an error occurred while importing the database
        debugPrint("TemplateService: An error occurred while importing $db");
        return;
      }

      dbViews.add(res);
    }

    /// Import the document and embed the [dbViews]

    final String templateRes =
        await File('${directory.path}/${doc.name}').readAsString();

    final Map<String, dynamic> docJson = json.decode(templateRes);

    final List<dynamic> children = docJson["document"]["children"];

    int dbCounter = 0;

    if (dbViews.isNotEmpty) {
      for (final child in children) {
        if (child["type"] == "grid" || child["type"] == "board") {
          /// Update old ID's with new ID's
          child["data"]["view_id"] = dbViews[dbCounter++].id;
          child["data"]["parent_id"] = parentViewId;
        }
      }
    }

    final document = Document.fromJson({
      "document": {
        "type": "page",
        "children": children,
      }
    });

    final docBytes =
        DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();

    await ImportBackendService.importData(
      docBytes!,
      doc.name,
      parentViewId,
      ImportTypePB.HistoryDocument,
    );
  }
}

Future<ViewPB?> _importDB(String db, String parentViewId) async {
  final directory = await getTemporaryDirectory();

  final dbRes = await File('${directory.path}/$db').readAsString();

  final res = await ImportBackendService.importData(
    utf8.encode(dbRes),
    db,
    parentViewId,
    ImportTypePB.CSV,
  );

  return res.fold((l) => l, (r) => null);
}

/// [TemplateModel] is the structure for [config.json] file

class TemplateModel {
  String templateName;
  List<DocumentModel> documents;

  TemplateModel({
    required this.templateName,
    required this.documents,
  });

  factory TemplateModel.fromRawJson(String str) =>
      TemplateModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TemplateModel.fromJson(Map<String, dynamic> json) => TemplateModel(
        templateName: json["templateName"],
        documents: List<DocumentModel>.from(
            json["documents"].map((x) => DocumentModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "templateName": templateName,
        "documents": List<dynamic>.from(documents.map((x) => x.toJson())),
      };
}

/// [DocumentModel] is the structure for each document in [config.json] file

class DocumentModel {
  String name;
  List<String> db;

  DocumentModel({
    required this.name,
    required this.db,
  });

  factory DocumentModel.fromRawJson(String str) =>
      DocumentModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        name: json["name"],
        db: List<String>.from(json["db"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "db": List<dynamic>.from(db.map((x) => x)),
      };
}
