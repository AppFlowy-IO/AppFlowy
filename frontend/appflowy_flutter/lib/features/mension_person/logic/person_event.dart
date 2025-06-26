import 'package:appflowy/features/mension_person/data/models/person.dart';

sealed class PersonEvent {
  const PersonEvent();

  const factory PersonEvent.initial() = InitialEvent;

  const factory PersonEvent.updatePerson(Person person) = UpdatePersonEvent;
}

class InitialEvent implements PersonEvent {
  const InitialEvent();
}

class UpdatePersonEvent implements PersonEvent {
  const UpdatePersonEvent(this.person);

  final Person person;
}
