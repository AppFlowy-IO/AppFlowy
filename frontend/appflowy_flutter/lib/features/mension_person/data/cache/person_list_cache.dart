import 'package:appflowy/features/mension_person/data/models/models.dart';

class PersonListCache {
  final Map<String, List<Person>> _cache = {};

  void updatePersonList(String workspaceId, List<Person> persons) {
    _cache[workspaceId] = List.of(persons);
  }

  List<Person>? getPersons(String workspaceId) {
    final persons = _cache[workspaceId];
    if (persons == null) return null;
    return List.of(persons);
  }

  void updatePerson(String workspaceId, Person person) {
    final persons = _cache[workspaceId];
    if (persons == null) return;
    final index = persons.indexWhere((p) => p.id == person.id);
    if (index == -1) return;
    persons[index] = person;
    _cache[workspaceId] = persons;
  }
}
