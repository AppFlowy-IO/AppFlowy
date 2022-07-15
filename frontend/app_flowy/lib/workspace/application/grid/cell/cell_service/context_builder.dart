part of 'cell_service.dart';

typedef GridCellController = IGridCellController<String, String>;
typedef GridSelectOptionCellController = IGridCellController<SelectOptionCellData, String>;
typedef GridDateCellController = IGridCellController<DateCellData, CalendarData>;
typedef GridURLCellController = IGridCellController<URLCellData, String>;

class GridCellControllerBuilder {
  final GridCell _gridCell;
  final GridCellsCache _cellCache;
  final GridFieldCache _fieldCache;

  GridCellControllerBuilder(
      {required GridCell gridCell, required GridCellsCache cellCache, required GridFieldCache fieldCache})
      : _cellCache = cellCache,
        _fieldCache = fieldCache,
        _gridCell = gridCell;

  IGridCellController build() {
    final cellFieldNotifier = GridCellFieldNotifier(notifier: _GridFieldChangedNotifierImpl(_fieldCache));

    switch (_gridCell.field.fieldType) {
      case FieldType.Checkbox:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: StringCellDataParser(),
        );
        return GridCellController(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellFieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.DateTime:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: DateCellDataParser(),
          config: const GridCellDataConfig(reloadOnFieldChanged: true),
        );

        return GridDateCellController(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellFieldNotifier: cellFieldNotifier,
          cellDataPersistence: DateCellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.Number:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: StringCellDataParser(),
          config: const GridCellDataConfig(reloadOnFieldChanged: true),
        );
        return GridCellController(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellFieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.RichText:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: StringCellDataParser(),
        );
        return GridCellController(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellFieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: SelectOptionCellDataParser(),
          config: const GridCellDataConfig(reloadOnFieldChanged: true),
        );

        return GridSelectOptionCellController(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellFieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );

      case FieldType.URL:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: URLCellDataParser(),
        );
        return GridURLCellController(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellFieldNotifier: cellFieldNotifier,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
    }
    throw UnimplementedError;
  }
}

// T: the type of the CellData
// D: the type of the data that will be saved to disk
// ignore: must_be_immutable
class IGridCellController<T, D> extends Equatable {
  final GridCell gridCell;
  final GridCellsCache _cellsCache;
  final GridCellId _cacheKey;
  final FieldService _fieldService;
  final GridCellFieldNotifier _cellFieldNotifier;
  // final GridCellFieldNotifier _fieldNotifier;
  final IGridCellDataLoader<T> _cellDataLoader;
  final IGridCellDataPersistence<D> _cellDataPersistence;

  late final CellListener _cellListener;
  ValueNotifier<T?>? _cellDataNotifier;

  bool isListening = false;
  VoidCallback? _onFieldChangedFn;
  Timer? _loadDataOperation;
  Timer? _saveDataOperation;
  bool isDispose = false;

  IGridCellController({
    required this.gridCell,
    required GridCellsCache cellCache,
    required GridCellFieldNotifier cellFieldNotifier,
    required IGridCellDataLoader<T> cellDataLoader,
    required IGridCellDataPersistence<D> cellDataPersistence,
    // required GridFieldChangedNotifier notifierDelegate,
  })  : _cellsCache = cellCache,
        _cellDataLoader = cellDataLoader,
        _cellDataPersistence = cellDataPersistence,
        _cellFieldNotifier = cellFieldNotifier,
        _fieldService = FieldService(gridId: gridCell.gridId, fieldId: gridCell.field.id),
        _cacheKey = GridCellId(rowId: gridCell.rowId, fieldId: gridCell.field.id);

  IGridCellController<T, D> clone() {
    return IGridCellController(
        gridCell: gridCell,
        cellDataLoader: _cellDataLoader,
        cellCache: _cellsCache,
        cellFieldNotifier: _cellFieldNotifier,
        cellDataPersistence: _cellDataPersistence);
  }

  String get gridId => gridCell.gridId;

  String get rowId => gridCell.rowId;

  String get cellId => gridCell.rowId + gridCell.field.id;

  String get fieldId => gridCell.field.id;

  Field get field => gridCell.field;

  FieldType get fieldType => gridCell.field.fieldType;

  VoidCallback? startListening({required void Function(T?) onCellChanged, VoidCallback? onCellFieldChanged}) {
    if (isListening) {
      Log.error("Already started. It seems like you should call clone first");
      return null;
    }
    isListening = true;

    /// The cell data will be changed by two reasons:
    /// 1. User edit the cell
    /// 2. User edit the field
    ///   For example: The number cell reload the cell data that carries the format
    ///   user input: 12
    ///   cell display: $12
    _cellDataNotifier = ValueNotifier(_cellsCache.get(_cacheKey));
    _cellListener = CellListener(rowId: gridCell.rowId, fieldId: gridCell.field.id);

    /// 1.Listen on user edit event and load the new cell data if needed.
    _cellListener.start(onCellChanged: (result) {
      result.fold(
        (_) => _loadData(),
        (err) => Log.error(err),
      );
    });

    /// 2.Listen on the field event and load the cell data if needed.
    _onFieldChangedFn = () {
      if (onCellFieldChanged != null) {
        onCellFieldChanged();
      }

      if (_cellDataLoader.config.reloadOnFieldChanged) {
        _loadData();
      }
    };

    _cellFieldNotifier.addFieldListener(_cacheKey, _onFieldChangedFn!);

    /// Notify the listener, the cell data was changed.
    onCellChangedFn() => onCellChanged(_cellDataNotifier?.value);
    _cellDataNotifier?.addListener(onCellChangedFn);
    return onCellChangedFn;
  }

  void removeListener(VoidCallback fn) {
    _cellDataNotifier?.removeListener(fn);
  }

  T? getCellData({bool loadIfNoCache = true}) {
    final data = _cellsCache.get(_cacheKey);
    if (data == null && loadIfNoCache) {
      _loadData();
    }
    return data;
  }

  Future<Either<FieldTypeOptionData, FlowyError>> getTypeOptionData() {
    return _fieldService.getFieldTypeOptionData(fieldType: fieldType);
  }

  void saveCellData(D data, {bool deduplicate = false, void Function(Option<FlowyError>)? resultCallback}) async {
    if (deduplicate) {
      _loadDataOperation?.cancel();
      _loadDataOperation = Timer(const Duration(milliseconds: 300), () async {
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
    _loadDataOperation?.cancel();
    _loadDataOperation = Timer(const Duration(milliseconds: 10), () {
      _cellDataLoader.loadData().then((data) {
        _cellDataNotifier?.value = data;
        _cellsCache.insert(_GridCellCacheItem(key: _cacheKey, object: data));
      });
    });
  }

  void dispose() {
    if (isDispose) {
      Log.error("$this should only dispose once");
      return;
    }
    isDispose = true;
    _cellListener.stop();
    _loadDataOperation?.cancel();
    _saveDataOperation?.cancel();
    _cellDataNotifier = null;

    if (_onFieldChangedFn != null) {
      _cellFieldNotifier.removeFieldListener(_cacheKey, _onFieldChangedFn!);
      _onFieldChangedFn = null;
    }
  }

  @override
  List<Object> get props => [_cellsCache.get(_cacheKey) ?? "", cellId];
}

class _GridFieldChangedNotifierImpl extends GridFieldChangedNotifier {
  final GridFieldCache _cache;
  FieldChangesetCallback? _onChangesetFn;

  _GridFieldChangedNotifierImpl(GridFieldCache cache) : _cache = cache;

  @override
  void dispose() {
    if (_onChangesetFn != null) {
      _cache.removeListener(onChangsetListener: _onChangesetFn!);
      _onChangesetFn = null;
    }
  }

  @override
  void onFieldChanged(void Function(Field p1) callback) {
    _onChangesetFn = (GridFieldChangeset changeset) {
      for (final updatedField in changeset.updatedFields) {
        callback(updatedField);
      }
    };
    _cache.addListener(onChangeset: _onChangesetFn);
  }
}
