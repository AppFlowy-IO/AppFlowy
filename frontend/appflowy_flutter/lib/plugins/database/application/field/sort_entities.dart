import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:equatable/equatable.dart';

final class DatabaseSort extends Equatable {
  const DatabaseSort({
    required this.sortId,
    required this.fieldId,
    required this.condition,
  });

  DatabaseSort.fromPB(SortPB sort)
      : sortId = sort.id,
        fieldId = sort.fieldId,
        condition = sort.condition;

  final String sortId;
  final String fieldId;
  final SortConditionPB condition;

  @override
  List<Object> get props => [sortId, fieldId, condition];
}
