import 'package:appflowy/features/mension_person/data/models/person.dart';

class PersonState {
  factory PersonState.initial() => PersonState(person: Person.empty());

  const PersonState({
    required this.person,
    this.documentId,
    this.access = false,
    this.getPersonFailedMesssage = '',
  });

  final Person person;
  final String? documentId;
  final bool access;
  final String getPersonFailedMesssage;

  PersonState copyWith({
    Person? person,
    String? documentId,
    bool? access,
    String? getPersonFailedMesssage,
  }) {
    return PersonState(
      person: person ?? this.person,
      documentId: documentId ?? this.documentId,
      access: access ?? this.access,
      getPersonFailedMesssage:
          getPersonFailedMesssage ?? this.getPersonFailedMesssage,
    );
  }

  @override
  String toString() {
    return 'PersonState(person: $person, documentId: $documentId, access: $access, getPersonFailedMesssage: $getPersonFailedMesssage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PersonState &&
        other.person == person &&
        other.documentId == documentId &&
        other.access == access &&
        other.getPersonFailedMesssage == getPersonFailedMesssage;
  }

  @override
  int get hashCode {
    return person.hashCode ^
        documentId.hashCode ^
        access.hashCode ^
        getPersonFailedMesssage.hashCode;
  }
}
