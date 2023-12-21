enum TemplateType { manual, resume, todo, journal }

class TemplateDescription {
  final String name;
  final String path;
  final TemplateType type;

  TemplateDescription({
    required this.name,
    required this.type,
    required this.path,
  });
}

final inbuiltTemplates = [
  TemplateDescription(
    name: "Pick from system",
    type: TemplateType.manual,
    path: "",
  ),
  TemplateDescription(
    name: "Resume/CV",
    type: TemplateType.resume,
    path: "assets/template/resume.zip",
  ),
  TemplateDescription(
    name: "ToDo List",
    type: TemplateType.todo,
    path: "assets/template/todos.zip",
  ),
  TemplateDescription(
    name: "Daily Journal",
    type: TemplateType.journal,
    path: "assets/template/journal.zip",
  ),
];
