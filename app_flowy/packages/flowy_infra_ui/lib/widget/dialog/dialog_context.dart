import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class DialogContext extends Equatable {
  bool get barrierDismissable => true;
  final String identifier;

  const DialogContext({required this.identifier});
  Widget buildWiget(BuildContext context);
}
