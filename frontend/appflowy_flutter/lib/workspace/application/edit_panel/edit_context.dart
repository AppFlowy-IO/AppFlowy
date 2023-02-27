import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class EditPanelContext extends Equatable {
  final String identifier;
  final String title;
  final Widget child;
  const EditPanelContext(
      {required this.child, required this.identifier, required this.title});

  @override
  List<Object> get props => [identifier];
}
