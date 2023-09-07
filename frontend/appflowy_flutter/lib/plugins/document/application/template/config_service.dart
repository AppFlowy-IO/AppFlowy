import 'dart:convert';
import 'dart:io';

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
    ),
  );

  initConfig(ViewPB view) async {
    final docModel = await _generateConfig(view, _template.documents);
    if (docModel != null) _template.documents = docModel;
  }

  Future<FlowyTemplateItem?> _generateConfig(
    ViewPB view,
    FlowyTemplateItem model,
  ) async {
    final viewsAtId = await ViewBackendService.getChildViews(viewId: view.id);
    final List<ViewPB> views = viewsAtId.getLeftOrNull();

    if (views.isEmpty) return null;

    final images = await _getImagesInView(view);
    final FlowyTemplateItem newModel = FlowyTemplateItem(
      name: "${uuid()}.json",
      childViews: [],
      images: images,
    );

    for (int i = 0; i < views.length; i++) {
      final e = views[i];

      final temp = await ViewBackendService.getChildViews(viewId: e.id);
      final viewsAtE = temp.getLeftOrNull();

      // If children are empty no need to continue
      if (viewsAtE.isEmpty) {
        final viewImages = await _getImagesInView(e);
        newModel.childViews.add(_addData(e, viewImages));
      } else {
        final newDoc = await _generateConfig(e, newModel);

        if (newDoc != null) {
          newModel.childViews.add(newDoc);
        }
      }
    }

    return newModel;
  }

  // If any document contains images we need to export it and
  // save the path in config.json
  Future<List<String>> _getImagesInView(ViewPB view) async {
    final images = <String>[];
    final directory = await getApplicationDocumentsDirectory();

    final data = await DocumentExporter(view).export(DocumentExportType.json);
    final String? jsonData = data.fold((l) => null, (r) => r);
    if (jsonData == null) return [];

    final document = json.decode(jsonData);
    final List<dynamic> children = document["document"]["children"];

    for (int i = 0; i < children.length; i++) {
      // Export images first, so that names can be determined
      if (children[i]["type"] == ImageBlockKeys.type) {
        final url = children[i]["data"]["url"] as String;

        final image = File.fromUri(Uri.parse(url));
        final bytes = await image.readAsBytes();

        final dir = Directory(path.join(directory.path, 'template'));
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }

        final extension = url.substring(url.lastIndexOf(".") + 1, url.length);

        // Store their unique names in config.json
        final name = "${uuid()}.$extension";
        await File(path.join(dir.path, name)).writeAsBytes(bytes);
        images.add(name);
      }
    }

    return images;
  }

  Future<FlowyTemplate> saveConfig() async {
    final directory = await getApplicationDocumentsDirectory();

    final dir = Directory(path.join(directory.path, 'template'));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    final file = File(
      path.join(directory.path, 'template', "config.json"),
    );

    await file.writeAsString(json.encode(_template.toJson()));
    return _template;
  }

  FlowyTemplateItem _addData(ViewPB view, List<String> images) {
    final FlowyTemplateItem newModel = FlowyTemplateItem(
      name: "",
      childViews: [],
      images: images,
    );

    // Generate unique name for each document
    final name = uuid();

    switch (view.layout) {
      case ViewLayoutPB.Document:
        newModel.name = "$name.json";
        break;
      case ViewLayoutPB.Grid:
      case ViewLayoutPB.Board:
        newModel.name = "$name.csv";
        break;
      default:
      // Eventually support calender
    }
    return newModel;
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
  });

  factory FlowyTemplateItem.fromJson(Map<String, dynamic> json) =>
      FlowyTemplateItem(
        name: json["name"],
        childViews: List<FlowyTemplateItem>.from(
          json["childViews"].map((x) => FlowyTemplateItem.fromJson(x)),
        ),
        images: List<String>.from(json["images"].map((x) => x.toString())),
      );

  Map<String, dynamic> toJson() {
    final processed = <FlowyTemplateItem>{};
    final result = <String, dynamic>{
      "name": name,
      "childViews": [],
      "images": images,
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

    final childViews = <dynamic>[];
    for (final child in model.childViews) {
      final childResult = <String, dynamic>{
        "name": child.name,
        "childViews": [],
        "images": child.images,
      };

      _toJsonHelper(child, processed, childResult);
      childViews.add(childResult);
    }

    result["childViews"] = childViews;
  }
}
