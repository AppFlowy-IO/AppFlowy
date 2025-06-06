import 'dart:math';

import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/data/repositories/person_repository.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class MockPersonRepository extends PersonRepository {
  @override
  Future<FlowyResult<PersonWithAccess, FlowyError>> getPerson({
    required String documentId,
    required String personId,
  }) async {
    return FlowySuccess(
      PersonWithAccess(
        person: _mockPersons[Random().nextInt(_mockPersons.length)],
        access: true,
      ),
    );
  }
}

List<Person> _mockPersons = [
  Person(
    id: '001',
    name: 'Andrew Christian',
    role: PersonRole.member,
    email: 'andrewchristian@appflowy.io',
    avatarUrl: 'https://avatar.iran.liara.run/public',
    description:
        'Andrew Christian is a software engineer with a passion for building scalable applications.',
    coverImageUrl:
        'https://images.unsplash.com/photo-1748882145961-536cc88fd117?q=80&w=2624&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ),
  Person(
    id: '002',
    name: 'Andrew Christian',
    role: PersonRole.guest,
    email: 'andrewchristian@appflowy.io',
    avatarUrl: 'https://avatar.iran.liara.run/public',
    description:
        'Andrew Christian is a software engineer with a passion for building scalable applications.',
  ),
  Person(
    id: '003',
    name: 'Andrew Christian',
    role: PersonRole.guest,
    email: 'andrewchristian@appflowy.io',
    avatarUrl: 'https://avatar.iran.liara.run/public',
  ),
];
