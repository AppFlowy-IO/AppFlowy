import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:dartz/dartz.dart';

class GridService {
  Future<Either<Grid, FlowyError>> createGrid({required String name}) {
    final payload = CreateGridPayload()..name = name;
    return GridEventCreateGrid(payload).send();
  }

  Future<Either<Grid, FlowyError>> openGrid({required String gridId}) {
    final payload = GridId(value: gridId);
    return GridEventOpenGrid(payload).send();
  }

  Future<Either<void, FlowyError>> createRow({required String gridId}) {
    throw UnimplementedError();
  }
}
