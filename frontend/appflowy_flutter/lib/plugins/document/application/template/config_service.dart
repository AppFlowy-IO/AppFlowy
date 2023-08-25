import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:path_provider/path_provider.dart';

/// Responsible to generate the [config.json] file for template

class ConfigService {
  final _template = FlowyTemplate(
    templateName: "template",
    documents: FlowyTemplateItem(name: "template.json", childViews: []),
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

    final FlowyTemplateItem newModel =
        FlowyTemplateItem(name: "${view.name}.json", childViews: []);

    for (final e in views) {
      final temp = await ViewBackendService.getChildViews(viewId: e.id);
      final viewsAtE = temp.getLeftOrNull();

      // If children are empty no need to continue
      if (viewsAtE.isEmpty) {
        newModel.childViews.add(addData(newModel, e));
      } else {
        final newDoc = await _generateConfig(e, newModel);

        if (newDoc != null) {
          newModel.childViews.add(newDoc);
        }
      }
    }

    return newModel;
  }

  Future<void> saveConfig() async {
    final directory = await getApplicationDocumentsDirectory();

    final dir = Directory(path.join(directory.path, 'template'));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    final file = File(
      path.join(directory.path, 'template', "config.json"),
    );

    await file.writeAsString(json.encode(_template.toJson()));
  }

  FlowyTemplateItem addData(FlowyTemplateItem model, ViewPB view) {
    final FlowyTemplateItem newModel = FlowyTemplateItem(
      name: "",
      childViews: [],
    );

    switch (view.layout) {
      case ViewLayoutPB.Document:
        newModel.name = "${view.name}.json";
        break;
      case ViewLayoutPB.Grid:
      case ViewLayoutPB.Board:
        final name = "${view.name}.csv";
        newModel.name = name;
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

  factory FlowyTemplate.fromRawJson(String str) =>
      FlowyTemplate.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

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
  // List<String> db;
  List<FlowyTemplateItem> childViews;

  FlowyTemplateItem({
    required this.name,
    // required this.db,
    required this.childViews,
  });

  factory FlowyTemplateItem.fromRawJson(String str) =>
      FlowyTemplateItem.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FlowyTemplateItem.fromJson(Map<String, dynamic> json) =>
      FlowyTemplateItem(
        name: json["name"],
        childViews: List<FlowyTemplateItem>.from(
          json["childViews"].map((x) => FlowyTemplateItem.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() {
    final processed = <FlowyTemplateItem>{};
    final result = <String, dynamic>{
      "name": name,
      "childViews": [],
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
      };

      _toJsonHelper(child, processed, childResult);
      childViews.add(childResult);
    }

    result["childViews"] = childViews;
  }
}
