class Person {
  Person({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.coverImageUrl,
    this.description,
  });

  final String id;
  final String name;
  final String email;
  final PersonRole role;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? description;
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
