import './operation.dart';

class Transaction {
  final List<Operation> operations;
  Transaction([this.operations = const []]);
}
