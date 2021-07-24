import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class EditPannelContext extends Equatable {
  final String identifier;
  final String title;
  final Widget child;
  const EditPannelContext(
      {required this.child, required this.identifier, required this.title});

  @override
  List<Object> get props => [identifier];
}

class BlankEditPannelContext extends EditPannelContext {
  const BlankEditPannelContext()
      : super(child: const Text('Blank'), identifier: '1', title: '');
}

class CellEditPannelContext extends EditPannelContext {
  const CellEditPannelContext()
      : super(child: const Text('shit'), identifier: 'test', title: 'test');
}
