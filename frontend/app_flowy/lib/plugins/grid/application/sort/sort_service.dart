import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pb.dart';

class SortFFIService {
  final String viewId;

  SortFFIService({required this.viewId});

  Future<Either<List<SortPB>, FlowyError>> getAllSorts() {
    final payload = GridIdPB()..value = viewId;

    return GridEventGetAllSorts(payload).send().then((result) {
      return result.fold(
        (repeated) => left(repeated.items),
        (r) => right(r),
      );
    });
  }
}
