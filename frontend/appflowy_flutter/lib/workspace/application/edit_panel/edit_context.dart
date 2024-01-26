import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class EditPanelContext extends Equatable {
  const EditPanelContext({
    required this.identifier,
    required this.title,
    required this.child,
  });

  final String identifier;
  final String title;
  final Widget child;

  @override
  List<Object> get props => [identifier];
}
