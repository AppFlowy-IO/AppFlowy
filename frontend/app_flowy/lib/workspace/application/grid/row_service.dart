import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';

class RowService {
  Future<Either<void, FlowyError>> createRow({required String gridId}) {
    return GridEventCreateRow(GridId(value: gridId)).send();
  }
}
