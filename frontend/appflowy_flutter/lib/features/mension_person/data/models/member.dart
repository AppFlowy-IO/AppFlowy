class Member {
  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.avatarUrl,
    this.coverImageUrl,
    this.description,
  });

  final String id;
  final String name;
  final String email;
  final MemberType type;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? description;
}

enum MemberType {
  member,
  guest,
  contact,
}
