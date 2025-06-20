class Person {
  Person({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.coverImageUrl,
    this.description,
    this.invited = false,
    this.deleted = false,
  });

  Person.empty()
      : id = '',
        name = '',
        email = '',
        role = PersonRole.member,
        avatarUrl = null,
        coverImageUrl = null,
        description = null,
        invited = false,
        deleted = false;

  final String id;
  final String name;
  final String email;
  final PersonRole role;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? description;
  final bool invited;
  final bool deleted;

  bool get isEmpty => id.isEmpty || email.isEmpty;
}

enum PersonRole {
  member,
  guest,
  contact,
}

class PersonWithAccess {
  PersonWithAccess({required this.person, required this.access});

  final Person person;
  final bool access;
}
