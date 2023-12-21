import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/database/database_view_block_component.dart';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:path_provider/path_provider.dart';

/// Responsible to generate the [config.json] file for template

class ConfigService {
  final _template = FlowyTemplate(
    templateName: "template",
    documents: FlowyTemplateItem(
      name: "template.json",
      childViews: [],
      images: [],
      databases: [],
    ),
  );

  // Updates Database Ids for reference grid feature
  Map<String, String> updateList = {};

  Future<void> initConfig(ViewPB view) async {
    _template.templateName = "${uuid()}.json";
    _template.documents.name = "${uuid()}.json";

    final docModel = await _generateConfig(view, _template.documents);
    if (docModel != null) _template.documents = docModel;

    for (var i = 0; i < updateList.keys.length; i++) {
      final oldId = updateList.keys.elementAt(i);
      final newId = updateList[oldId]!;
      updateDBName(_template.documents, oldId, newId);
    }
  }

  Future<FlowyTemplateItem?> _generateConfig(
    ViewPB view,
    FlowyTemplateItem model,
  ) async {
    final viewsAtId = await ViewBackendService.getChildViews(viewId: view.id);
    final List<ViewPB> views = viewsAtId.getLeftOrNull();

    final images = await _getImagesInView(view);
    final FlowyTemplateItem newModel = FlowyTemplateItem(
      name: "${uuid()}.json",
      childViews: [],
      images: images,
      databases: [],
    );

    if (view.layout == ViewLayoutPB.Document) {
      final databases = await _getDatabasesInView(view);
      newModel.databases = databases;
    }

    if (view.layout == ViewLayoutPB.Board || view.layout == ViewLayoutPB.Grid) {
      newModel.name = "${uuid()}.csv";
    }

    for (int i = 0; i < views.length; i++) {
      final e = views[i];

      final temp = await ViewBackendService.getChildViews(viewId: e.id);
      final viewsAtE = temp.getLeftOrNull() ?? [];

      if (viewsAtE.isEmpty) {
        final viewImages = await _getImagesInView(e);
        newModel.childViews.add(await _addData(e, viewImages));
      } else {
        final newDoc = await _generateConfig(e, newModel);

        if (newDoc != null) {
          newModel.childViews.add(newDoc);
        }
      }
    }

    return newModel;
  }

  Future<List<String>> _getDatabasesInView(ViewPB view) async {
    final List<String> databases = [];
    final data = await DocumentExporter(view).export(DocumentExportType.json);
    final String? jsonData = data.fold((l) => null, (r) => r);

    final document = json.decode(jsonData ?? "{}");
    final children = document["document"]["children"];

    for (int i = 0; i < children.length; i++) {
      if (children[i]["type"] == DatabaseBlockKeys.gridType ||
          children[i]["type"] == DatabaseBlockKeys.boardType) {
        databases.add(children[i]["data"]["view_id"]);
      }
    }
    return databases;
  }

  // If any document contains images we need to export it and
  // save the path in config.json
  Future<List<String>> _getImagesInView(ViewPB view) async {
    if (view.layout == ViewLayoutPB.Grid || view.layout == ViewLayoutPB.Board) {
      return [];
    }

    final images = <String>[];
    final directory = await getApplicationDocumentsDirectory();

    final data = await DocumentExporter(view).export(DocumentExportType.json);
    final String? jsonData = data.fold((l) => null, (r) => r);
    if (jsonData == null) return [];

    final document = json.decode(jsonData);
    final List<dynamic> children = document["document"]["children"];

    final dir = Directory(path.join(directory.path, 'template'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    for (int i = 0; i < children.length; i++) {
      // Export images first, so that names can be determined
      if (children[i]["type"] == ImageBlockKeys.type) {
        final url = children[i]["data"]["url"] as String;
        // if url is on local storage export it
        if (!url.startsWith("http")) {
          final image = File.fromUri(Uri.parse(url));
          final bytes = await image.readAsBytes();

          final extension = url.substring(url.lastIndexOf(".") + 1, url.length);

          // Store their unique names in config.json
          final name = "${uuid()}.$extension";
          await File(path.join(dir.path, name)).writeAsBytes(bytes);
          images.add(name);
        } else {
          images.add(url);
        }
      }
    }

    return images;
  }

  Future<FlowyTemplate> saveConfig() async {
    final directory = await getApplicationDocumentsDirectory();

    final dir = Directory(path.join(directory.path, 'template'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(
      path.join(directory.path, 'template', "config.json"),
    );

    await file.writeAsString(json.encode(_template.toJson()));
    return _template;
  }

  Future<FlowyTemplateItem> _addData(ViewPB view, List<String> images) async {
    final FlowyTemplateItem newModel = FlowyTemplateItem(
      name: "",
      childViews: [],
      images: images,
      databases: [],
    );

    // Generate unique name for each document
    final name = uuid();

    switch (view.layout) {
      case ViewLayoutPB.Document:
        {
          // Check if the document contains database
          final data =
              await DocumentExporter(view).export(DocumentExportType.json);
          final String? jsonData = data.fold((l) => null, (r) => r);

          final document = json.decode(jsonData ?? "{}");
          final children = document["document"]["children"];

          for (int i = 0; i < children.length; i++) {
            if (children[i]["type"] == DatabaseBlockKeys.gridType ||
                children[i]["type"] == DatabaseBlockKeys.boardType) {
              newModel.databases.add(children[i]["data"]["view_id"]);
            }
          }
          newModel.name = "$name.json";
          break;
        }
      case ViewLayoutPB.Grid:
      case ViewLayoutPB.Board:
        {
          updateList[view.id] = name;
          newModel.name = "$name.csv";
          break;
        }
      default:
      // Eventually support calender
    }
    return newModel;
  }

  FlowyTemplateItem updateDBName(
    FlowyTemplateItem item,
    String oldId,
    String newId,
  ) {
    if (item.databases.contains(oldId)) {
      item.databases.remove(oldId);
      item.databases.add(newId);
    }

    for (var i = 0; i < item.childViews.length; i++) {
      item.childViews[i] = updateDBName(item.childViews[i], oldId, newId);
    }

    return item;
  }
}

/// [FlowyTemplate] is the structure for [config.json] file
class FlowyTemplate {
  String templateName;
  FlowyTemplateItem documents;

  FlowyTemplate({
    required this.templateName,
    required this.documents,
  });

  factory FlowyTemplate.fromJson(Map<String, dynamic> json) => FlowyTemplate(
        templateName: json["templateName"],
        documents: FlowyTemplateItem.fromJson(json["documents"]),
      );

  Map<String, dynamic> toJson() => {
        "templateName": templateName,
        "documents": documents.toJson(),
      };
}

/// [FlowyTemplateItem] is the structure for each document in [config.json] file
class FlowyTemplateItem {
  String name;
  List<String> databases = [];
  List<String> images = [];
  List<FlowyTemplateItem> childViews = [];

  FlowyTemplateItem({
    required this.name,
    required this.images,
    required this.childViews,
    required this.databases,
  });

  factory FlowyTemplateItem.fromJson(Map<String, dynamic> json) =>
      FlowyTemplateItem(
        name: json["name"],
        childViews: List<FlowyTemplateItem>.from(
          json["childViews"].map((x) => FlowyTemplateItem.fromJson(x)),
        ),
        images: List<String>.from(json["images"].map((x) => x.toString())),
        databases:
            List<String>.from(json["databases"].map((x) => x.toString())),
      );

  Map<String, dynamic> toJson() {
    final processed = <FlowyTemplateItem>{};
    final result = <String, dynamic>{
      "name": name,
      "childViews": [],
      "images": images,
      "databases": databases,
    };

    _toJsonHelper(this, processed, result);

    return result;
  }

  void _toJsonHelper(
    FlowyTemplateItem model,
    Set<FlowyTemplateItem> processed,
    Map<String, dynamic> result,
  ) {
    if (processed.contains(model)) {
      return;
    }

    processed.add(model);

    if (model.childViews.isNotEmpty) {
      final childViews = <dynamic>[];
      for (final child in model.childViews) {
        final childResult = <String, dynamic>{
          "name": child.name,
          "childViews": [],
          "images": child.images,
          "databases": child.databases,
        };

        _toJsonHelper(child, processed, childResult);
        childViews.add(childResult);
      }

      result["childViews"] = childViews;
    }
  }
}
