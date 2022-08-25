part of 'cell_service.dart';

typedef GridCellController = IGridCellController<String, String>;
typedef GridCheckboxCellController = IGridCellController<String, String>;
typedef GridNumberCellController = IGridCellController<String, String>;
typedef GridSelectOptionCellController
    = IGridCellController<SelectOptionCellDataPB, String>;
typedef GridDateCellController
    = IGridCellController<DateCellDataPB, CalendarData>;
typedef GridURLCellController = IGridCellController<URLCellDataPB, String>;

abstract class GridCellControllerBuilderDelegate {
  GridCellFieldNotifier buildFieldNotifier();
}

class GridCellControllerBuilder {
  final GridCellIdentifier _cellId;
  final GridCellCache _cellCache;
  final GridCellControllerBuilderDelegate delegate;

  GridCellControllerBuilder({
    required this.delegate,
    required GridCellIdentifier cellId,
    required GridCellCache cellCache,
  })  : _cellCache = cellCache,
        _cellId = cellId;

  IGridCellController build() {
    final cellFieldNotifier = delegate.buildFieldNotifier();
    switch (_cellId.fieldType) {
      case FieldType.Checkbox:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: StringCellDataParser(),
        );
        return GridCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(cellId: _cellId),
        );
      case FieldType.DateTime:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: DateCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return GridDateCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: DateCellDataPersistence(cellId: _cellId),
        );
      case FieldType.Number:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: StringCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return GridNumberCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(cellId: _cellId),
        );
      case FieldType.RichText:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: StringCellDataParser(),
        );
        return GridCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(cellId: _cellId),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: SelectOptionCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return GridSelectOptionCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(cellId: _cellId),
        );

      case FieldType.URL:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: URLCellDataParser(),
        );
        return GridURLCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(cellId: _cellId),
        );
    }
    throw UnimplementedError;
  }
}

/// IGridCellController is used to manipulate the cell and receive notifications.
/// * Read/Write cell data
/// * Listen on field/cell notifications.
///
/// Generic T represents the type of the cell data.
/// Generic D represents the type of data that will be saved to the disk
///
// ignore: must_be_immutable
class IGridCellController<T, D> extends Equatable {
  final GridCellIdentifier cellId;
  final GridCellCache _cellsCache;
  final GridCellCacheKey _cacheKey;
  final FieldService _fieldService;
  final GridCellFieldNotifier _fieldNotifier;
  final GridCellDataLoader<T> _cellDataLoader;
  final IGridCellDataPersistence<D> _cellDataPersistence;

  CellListener? _cellListener;
  ValueNotifier<T?>? _cellDataNotifier;

  bool isListening = false;
  VoidCallback? _onFieldChangedFn;
  Timer? _loadDataOperation;
  Timer? _saveDataOperation;
  bool _isDispose = false;

  IGridCellController({
    required this.cellId,
    required GridCellCache cellCache,
    required GridCellFieldNotifier fieldNotifier,
    required GridCellDataLoader<T> cellDataLoader,
    required IGridCellDataPersistence<D> cellDataPersistence,
  })  : _cellsCache = cellCache,
        _cellDataLoader = cellDataLoader,
        _cellDataPersistence = cellDataPersistence,
        _fieldNotifier = fieldNotifier,
        _fieldService =
            FieldService(gridId: cellId.gridId, fieldId: cellId.field.id),
        _cacheKey =
            GridCellCacheKey(rowId: cellId.rowId, fieldId: cellId.field.id);

  IGridCellController<T, D> clone() {
    return IGridCellController(
        cellId: cellId,
        cellDataLoader: _cellDataLoader,
        cellCache: _cellsCache,
        fieldNotifier: _fieldNotifier,
        cellDataPersistence: _cellDataPersistence);
  }

  String get gridId => cellId.gridId;

  String get rowId => cellId.rowId;

  String get fieldId => cellId.field.id;

  FieldPB get field => cellId.field;

  FieldType get fieldType => cellId.field.fieldType;

  VoidCallback? startListening(
      {required void Function(T?) onCellChanged,
      VoidCallback? onCellFieldChanged}) {
    if (isListening) {
      Log.error("Already started. It seems like you should call clone first");
      return null;
    }
    isListening = true;

    _cellDataNotifier = ValueNotifier(_cellsCache.get(_cacheKey));
    _cellListener = CellListener(rowId: cellId.rowId, fieldId: cellId.field.id);

    /// 1.Listen on user edit event and load the new cell data if needed.
    /// For example:
    ///  user input: 12
    ///  cell display: $12
    _cellListener?.start(onCellChanged: (result) {
      result.fold(
        (_) {
          _cellsCache.remove(fieldId);
          _loadData();
        },
        (err) => Log.error(err),
      );
    });

    /// 2.Listen on the field event and load the cell data if needed.
    _onFieldChangedFn = () {
      if (onCellFieldChanged != null) {
        onCellFieldChanged();
      }

      /// reloadOnFieldChanged should be true if you need to load the data when the corresponding field is changed
      /// For example:
      ///   ￥12 -> $12
      if (_cellDataLoader.reloadOnFieldChanged) {
        _loadData();
      }
    };

    _fieldNotifier.register(_cacheKey, _onFieldChangedFn!);

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
    final data = _cellsCache.get(_cacheKey);
    if (data == null && loadIfNotExist) {
      _loadData();
    }
    return data;
  }

  /// Return the FieldTypeOptionDataPB that can be parsed into corresponding class using the [parser].
  /// [PD] is the type that the parser return.
  Future<Either<PD, FlowyError>>
      getFieldTypeOption<PD, P extends TypeOptionDataParser>(P parser) {
    return _fieldService
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
  void saveCellData(D data,
      {bool deduplicate = false,
      void Function(Option<FlowyError>)? resultCallback}) async {
    if (deduplicate) {
      _loadDataOperation?.cancel();

      _saveDataOperation?.cancel();
      _saveDataOperation = Timer(const Duration(milliseconds: 300), () async {
        final result = await _cellDataPersistence.save(data);
        if (resultCallback != null) {
          resultCallback(result);
        }
      });
    } else {
      final result = await _cellDataPersistence.save(data);
      if (resultCallback != null) {
        resultCallback(result);
      }
    }
  }

  void _loadData() {
    _saveDataOperation?.cancel();

    _loadDataOperation?.cancel();
    _loadDataOperation = Timer(const Duration(milliseconds: 10), () {
      _cellDataLoader.loadData().then((data) {
        _cellsCache.insert(_cacheKey, GridCell(object: data));
        _cellDataNotifier?.value = data;
      });
    });
  }

  void dispose() {
    if (_isDispose) {
      Log.error("$this should only dispose once");
      return;
    }
    _isDispose = true;
    _cellListener?.stop();
    _loadDataOperation?.cancel();
    _saveDataOperation?.cancel();
    _cellDataNotifier = null;

    if (_onFieldChangedFn != null) {
      _fieldNotifier.unregister(_cacheKey, _onFieldChangedFn!);
      _fieldNotifier.dispose();
      _onFieldChangedFn = null;
    }
  }

  @override
  List<Object> get props =>
      [_cellsCache.get(_cacheKey) ?? "", cellId.rowId + cellId.field.id];
}

class GridCellFieldNotifierImpl extends IGridCellFieldNotifier {
  final GridFieldCache _cache;
  FieldChangesetCallback? _onChangesetFn;

  GridCellFieldNotifierImpl(GridFieldCache cache) : _cache = cache;

  @override
  void onCellDispose() {
    if (_onChangesetFn != null) {
      _cache.removeListener(onChangesetListener: _onChangesetFn!);
      _onChangesetFn = null;
    }
  }

  @override
  void onCellFieldChanged(void Function(FieldPB p1) callback) {
    _onChangesetFn = (FieldChangesetPB changeset) {
      for (final updatedField in changeset.updatedFields) {
        callback(updatedField);
      }
    };
    _cache.addListener(onChangeset: _onChangesetFn);
  }
}
