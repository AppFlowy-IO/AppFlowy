import 'dart:async';
import 'package:appflowy/plugins/database_view/application/field/field_listener.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../field/field_controller.dart';
import '../field/field_service.dart';
import '../field/type_option/type_option_context.dart';
import 'cell_listener.dart';
import 'cell_service.dart';

/// IGridCellController is used to manipulate the cell and receive notifications.
/// * Read/Write cell data
/// * Listen on field/cell notifications.
///
/// Generic T represents the type of the cell data.
/// Generic D represents the type of data that will be saved to the disk
///
// ignore: must_be_immutable
class CellController<T, D> extends Equatable {
  final DatabaseCellContext cellContext;
  final CellCache _cellCache;
  final CellCacheKey _cacheKey;
  final FieldBackendService _fieldBackendSvc;
  final SingleFieldListener _fieldListener;
  final CellDataLoader<T> _cellDataLoader;
  final CellDataPersistence<D> _cellDataPersistence;

  CellListener? _cellListener;
  CellDataNotifier<T?>? _cellDataNotifier;

  VoidCallback? _onCellFieldChanged;
  Timer? _loadDataOperation;
  Timer? _saveDataOperation;

  String get viewId => cellContext.viewId;

  RowId get rowId => cellContext.rowId;

  String get fieldId => cellContext.fieldInfo.id;

  FieldInfo get fieldInfo => cellContext.fieldInfo;

  FieldType get fieldType => cellContext.fieldInfo.fieldType;

  CellController({
    required this.cellContext,
    required CellCache cellCache,
    required CellDataLoader<T> cellDataLoader,
    required CellDataPersistence<D> cellDataPersistence,
  })  : _cellCache = cellCache,
        _cellDataLoader = cellDataLoader,
        _cellDataPersistence = cellDataPersistence,
        _fieldListener = SingleFieldListener(fieldId: cellContext.fieldId),
        _fieldBackendSvc = FieldBackendService(
          viewId: cellContext.viewId,
          fieldId: cellContext.fieldInfo.id,
        ),
        _cacheKey = CellCacheKey(
          rowId: cellContext.rowId,
          fieldId: cellContext.fieldInfo.id,
        ) {
    _cellDataNotifier = CellDataNotifier(value: _cellCache.get(_cacheKey));
    _cellListener = CellListener(
      rowId: cellContext.rowId,
      fieldId: cellContext.fieldInfo.id,
    );

    /// 1.Listen on user edit event and load the new cell data if needed.
    /// For example:
    ///  user input: 12
    ///  cell display: $12
    _cellListener?.start(
      onCellChanged: (result) {
        result.fold(
          (_) => _loadData(),
          (err) => Log.error(err),
        );
      },
    );

    /// 2.Listen on the field event and load the cell data if needed.
    _fieldListener.start(
      onFieldChanged: (result) {
        result.fold(
          (fieldPB) {
            /// reloadOnFieldChanged should be true if you need to load the data when the corresponding field is changed
            /// For example:
            ///   ￥12 -> $12
            if (_cellDataLoader.reloadOnFieldChanged) {
              _loadData();
            }
            _onCellFieldChanged?.call();
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  /// Listen on the cell content or field changes
  VoidCallback? startListening({
    required void Function(T?) onCellChanged,
    VoidCallback? onCellFieldChanged,
  }) {
    _onCellFieldChanged = onCellFieldChanged;

    /// Notify the listener, the cell data was changed.
    onCellChangedFn() => onCellChanged(_cellDataNotifier?.value);
    _cellDataNotifier?.addListener(onCellChangedFn);

    // Return the function pointer that can be used when calling removeListener.
    return onCellChangedFn;
  }

  void removeListener(VoidCallback fn) {
    _cellDataNotifier?.removeListener(fn);
  }

  /// Return the cell data.
  /// The cell data will be read from the Cache first, and load from disk if it does not exist.
  /// You can set [loadIfNotExist] to false (default is true) to disable loading the cell data.
  T? getCellData({bool loadIfNotExist = true}) {
    final data = _cellCache.get(_cacheKey);
    if (data == null && loadIfNotExist) {
      _loadData();
    }
    return data;
  }

  /// Return the TypeOptionPB that can be parsed into corresponding class using the [parser].
  /// [PD] is the type that the parser return.
  Future<Either<PD, FlowyError>> getTypeOption<PD, P extends TypeOptionParser>(
    P parser,
  ) {
    return _fieldBackendSvc
        .getFieldTypeOptionData(fieldType: fieldType)
        .then((result) {
      return result.fold(
        (data) => left(parser.fromBuffer(data.typeOptionData)),
        (err) => right(err),
      );
    });
  }

  /// Save the cell data to disk
  /// You can set [deduplicate] to true (default is false) to reduce the save operation.
  /// It's useful when you call this method when user editing the [TextField].
  /// The default debounce interval is 300 milliseconds.
  Future<void> saveCellData(
    D data, {
    bool deduplicate = false,
    void Function(Option<FlowyError>)? onFinish,
  }) async {
    _loadDataOperation?.cancel();
    if (deduplicate) {
      _saveDataOperation?.cancel();
      _saveDataOperation = Timer(const Duration(milliseconds: 300), () async {
        final result = await _cellDataPersistence.save(data);
        onFinish?.call(result);
      });
    } else {
      final result = await _cellDataPersistence.save(data);
      onFinish?.call(result);
    }
  }

  void _loadData() {
    _saveDataOperation?.cancel();
    _loadDataOperation?.cancel();

    _loadDataOperation = Timer(const Duration(milliseconds: 10), () {
      _cellDataLoader.loadData().then((data) {
        if (data != null) {
          _cellCache.insert(_cacheKey, DatabaseCell(object: data));
        } else {
          _cellCache.remove(_cacheKey);
        }
        _cellDataNotifier?.value = data;
      });
    });
  }

  Future<void> dispose() async {
    await _cellListener?.stop();
    _loadDataOperation?.cancel();
    _saveDataOperation?.cancel();
    _cellDataNotifier?.dispose();
    await _fieldListener.stop();
    _cellDataNotifier = null;
  }

  @override
  List<Object> get props => [
        _cellCache.get(_cacheKey) ?? "",
        cellContext.rowId + cellContext.fieldInfo.id
      ];
}

class CellDataNotifier<T> extends ChangeNotifier {
  T _value;
  bool Function(T? oldValue, T? newValue)? listenWhen;
  CellDataNotifier({required T value, this.listenWhen}) : _value = value;

  set value(T newValue) {
    if (listenWhen?.call(_value, newValue) ?? false) {
      _value = newValue;
      notifyListeners();
    } else {
      if (_value != newValue) {
        _value = newValue;
        notifyListeners();
      }
    }
  }

  T get value => _value;
}
