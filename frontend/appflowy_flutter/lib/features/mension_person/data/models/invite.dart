import 'package:flutter/material.dart';

import 'person.dart';

class InviteInfo {
  InviteInfo({
    required this.email,
    this.role = PersonRole.member,
    this.contactDetail,
  });

  final String email;
  final PersonRole role;
  final ContactDetail? contactDetail;

  InviteInfo copyWith({
    String? email,
    PersonRole? role,
    ValueGetter<ContactDetail?>? contactDetail,
  }) {
    return InviteInfo(
      email: email ?? this.email,
      role: role ?? this.role,
      contactDetail:
          contactDetail != null ? contactDetail() : this.contactDetail,
    );
  }
}

class ContactDetail {
  ContactDetail({
    this.name = '',
    this.description = '',
  });

  final String name;
  final String description;

  ContactDetail copyWith({
    String? name,
    String? description,
  }) {
    return ContactDetail(
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
