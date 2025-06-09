import 'dart:math';

import 'package:appflowy/features/mension_person/data/models/invite.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'mention_repository.dart';

class MockMentionRepository extends MentionRepository {
  @override
  Future<FlowyResult<List<Person>, FlowyError>> getPersons({
    required String workspaceId,
  }) async {
    return FlowySuccess(_MockState.getInstance().persons);
  }

  @override
  Future<FlowyResult<Person, FlowyError>> invitePerson({
    required String workspaceId,
    required InviteInfo info,
  }) async {
    try {
      final person = _MockState.getInstance().invitePerson(info);
      return FlowySuccess(person);
    } on FormatException catch (e) {
      return FlowyFailure(
        FlowyError(code: ErrorCode.EmailAlreadyExists, msg: e.message),
      );
    }
  }

  @override
  Future<FlowyResult<PersonWithAccess, FlowyError>> getPerson({
    required String workspaceId,
    required String documentId,
    required String personId,
  }) async {
    final persons = _MockState.getInstance().persons;
    final person = persons.where((p) => p.id == personId).firstOrNull;
    if (person == null) {
      return FlowyFailure(
        FlowyError(code: ErrorCode.RecordNotFound, msg: 'Person not found'),
      );
    }
    return FlowySuccess(
      PersonWithAccess(person: person, access: true),
    );
  }
}

class _MockState {
  _MockState._();

  static _MockState? _instance;

  static _MockState getInstance() {
    _instance ??= _MockState._();
    return _instance!;
  }

  final List<Person> persons = [
    Person(
      id: '1',
      name: 'Andrew Christian',
      role: PersonRole.member,
      email: 'andrewchristian@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public',
    ),
    Person(
      id: '2',
      name: 'Andrew Tate',
      role: PersonRole.member,
      email: 'andrewtate@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/boy',
    ),
    Person(
      id: '3',
      name: 'Emma Johnson',
      role: PersonRole.member,
      email: 'emmajohnson@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/girl',
    ),
    Person(
      id: '4',
      name: 'Michael Brown',
      role: PersonRole.member,
      email: 'michaelbrown@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/13',
    ),
    Person(
      id: '5',
      name: 'Nathan Brooks',
      role: PersonRole.member,
      email: 'nathanbrooks@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/10',
    ),
  ];

  Person invitePerson(InviteInfo info) {
    final index = persons.indexWhere((p) => p.email == info.email);
    if (index != -1) {
      throw FormatException('Person with email ${info.email} already exists');
    }
    final person = Person(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: info.contactDetail?.name ?? info.email,
      role: info.role,
      email: info.email,
      description: info.contactDetail?.description ?? '',
      avatarUrl: randomAvatarUrl,
      coverImageUrl: Random().nextBool()
          ? null
          : 'https://images.unsplash.com/photo-1748882145961-536cc88fd117?q=80&w=2624&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    );
    persons.add(person);
    return person;
  }

  String get randomAvatarUrl =>
      'https://avatar.iran.liara.run/public/${Random().nextBool() ? 'boy' : 'girl'}/${Random().nextInt(100)}';
}
