import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/cell_listener.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/domain/row_meta_listener.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'cell_cache.dart';
import 'cell_data_loader.dart';
import 'cell_data_persistence.dart';

part 'cell_controller.freezed.dart';

@freezed
class CellContext with _$CellContext {
  const factory CellContext({
    required String fieldId,
    required RowId rowId,
  }) = _DatabaseCellContext;
}

/// [CellController] is used to manipulate the cell and receive notifications.
/// The cell data is stored in the [RowCache]'s [CellMemCache].
///
/// * Read/write cell data
/// * Listen on field/cell notifications.
///
/// T represents the type of the cell data.
/// D represents the type of data that will be saved to the disk.
class CellController<T, D> {
  CellController({
    required this.viewId,
    required FieldController fieldController,
    required CellContext cellContext,
    required RowCache rowCache,
    required CellDataLoader<T> cellDataLoader,
    required CellDataPersistence<D> cellDataPersistence,
  })  : _fieldController = fieldController,
        _cellContext = cellContext,
        _rowCache = rowCache,
        _cellDataLoader = cellDataLoader,
        _cellDataPersistence = cellDataPersistence,
        _cellDataNotifier =
            CellDataNotifier(value: rowCache.cellCache.get(cellContext)) {
    _startListening();
  }

  final String viewId;
  final FieldController _fieldController;
  final CellContext _cellContext;
  final RowCache _rowCache;
  final CellDataLoader<T> _cellDataLoader;
  final CellDataPersistence<D> _cellDataPersistence;

  CellListener? _cellListener;
  RowMetaListener? _rowMetaListener;
  CellDataNotifier<T?>? _cellDataNotifier;

  VoidCallback? _onRowMetaChanged;
  Timer? _loadDataOperation;
  Timer? _saveDataOperation;

  RowId get rowId => _cellContext.rowId;
  String get fieldId => _cellContext.fieldId;
  FieldInfo get fieldInfo => _fieldController.getField(_cellContext.fieldId)!;
  FieldType get fieldType =>
      _fieldController.getField(_cellContext.fieldId)!.fieldType;
  RowMetaPB? get rowMeta => _rowCache.getRow(rowId)?.rowMeta;
  String? get icon => rowMeta?.icon;
  CellMemCache get _cellCache => _rowCache.cellCache;

  /// casting method for painless type coersion
  CellController<A, B> as<A, B>() => this as CellController<A, B>;

  /// Start listening to backend changes
  void _startListening() {
    _cellListener = CellListener(
      rowId: _cellContext.rowId,
      fieldId: _cellContext.fieldId,
    );

    // 1. Listen on user edit event and load the new cell data if needed.
    // For example:
    //  user input: 12
    //  cell display: $12
    _cellListener?.start(
      onCellChanged: (result) {
        result.fold(
          (_) => _loadData(),
          (err) => Log.error(err),
        );
      },
    );

    // 2. Listen on the field event and load the cell data if needed.
    _fieldController.addSingleFieldListener(
      fieldId,
      onFieldChanged: _onFieldChangedListener,
    );

    // 3. If the field is primary listen to row meta changes.
    if (fieldInfo.field.isPrimary) {
      _rowMetaListener = RowMetaListener(_cellContext.rowId);
      _rowMetaListener?.start(
        callback: (newRowMeta) {
          _onRowMetaChanged?.call();
        },
      );
    }
  }

  /// Add a new listener
  VoidCallback? addListener({
    required void Function(T?) onCellChanged,
    void Function(FieldInfo fieldInfo)? onFieldChanged,
    VoidCallback? onRowMetaChanged,
  }) {
    /// an adaptor for the onCellChanged listener
    void onCellChangedFn() => onCellChanged(_cellDataNotifier?.value);
    _cellDataNotifier?.addListener(onCellChangedFn);

    if (onFieldChanged != null) {
      _fieldController.addSingleFieldListener(
        fieldId,
        onFieldChanged: onFieldChanged,
      );
    }

    _onRowMetaChanged = onRowMetaChanged;

    // Return the function pointer that can be used when calling removeListener.
    return onCellChangedFn;
  }

  void removeListener({
    required VoidCallback onCellChanged,
    void Function(FieldInfo fieldInfo)? onFieldChanged,
    VoidCallback? onRowMetaChanged,
  }) {
    _cellDataNotifier?.removeListener(onCellChanged);

    if (onFieldChanged != null) {
      _fieldController.removeSingleFieldListener(
        fieldId: fieldId,
        onFieldChanged: onFieldChanged,
      );
    }
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    // reloadOnFieldChanged should be true if you want to reload the cell
    // data when the corresponding field is changed.
    // For example:
    //   ￥12 -> $12
    if (_cellDataLoader.reloadOnFieldChange) {
      _loadData();
    }
  }

  /// Get the cell data. The cell data will be read from the cache first,
  /// and load from disk if it doesn't exist. You can set [loadIfNotExist] to
  /// false to disable this behavior.
  T? getCellData({bool loadIfNotExist = true}) {
    final T? data = _cellCache.get(_cellContext);
    if (data == null && loadIfNotExist) {
      _loadData();
    }
    return data;
  }

  /// Return the TypeOptionPB that can be parsed into corresponding class using the [parser].
  /// [PD] is the type that the parser return.
  PD getTypeOption<PD>(TypeOptionParser parser) {
    return parser.fromBuffer(fieldInfo.field.typeOptionData);
  }

  /// Saves the cell data to disk. You can set [debounce] to reduce the amount
  /// of save operations, which is useful when editing a [TextField].
  Future<void> saveCellData(
    D data, {
    bool debounce = false,
    void Function(FlowyError?)? onFinish,
  }) async {
    _loadDataOperation?.cancel();
    if (debounce) {
      _saveDataOperation?.cancel();
      _saveDataOperation = Timer(const Duration(milliseconds: 300), () async {
        final result = await _cellDataPersistence.save(
          viewId: viewId,
          cellContext: _cellContext,
          data: data,
        );
        onFinish?.call(result);
      });
    } else {
      final result = await _cellDataPersistence.save(
        viewId: viewId,
        cellContext: _cellContext,
        data: data,
      );
      onFinish?.call(result);
    }
  }

  void _loadData() {
    _saveDataOperation?.cancel();
    _loadDataOperation?.cancel();

    _loadDataOperation = Timer(const Duration(milliseconds: 10), () {
      _cellDataLoader
          .loadData(viewId: viewId, cellContext: _cellContext)
          .then((data) {
        if (data != null) {
          _cellCache.insert(_cellContext, data);
        } else {
          _cellCache.remove(_cellContext);
        }
        _cellDataNotifier?.value = data;
      });
    });
  }

  Future<void> dispose() async {
    await _rowMetaListener?.stop();
    _rowMetaListener = null;

    await _cellListener?.stop();
    _cellListener = null;

    _fieldController.removeSingleFieldListener(
      fieldId: fieldId,
      onFieldChanged: _onFieldChangedListener,
    );

    _loadDataOperation?.cancel();
    _saveDataOperation?.cancel();
    _cellDataNotifier?.dispose();
    _cellDataNotifier = null;
    _onRowMetaChanged = null;
  }
}

class CellDataNotifier<T> extends ChangeNotifier {
  CellDataNotifier({required T value, this.listenWhen}) : _value = value;

  T _value;
  bool Function(T? oldValue, T? newValue)? listenWhen;

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
