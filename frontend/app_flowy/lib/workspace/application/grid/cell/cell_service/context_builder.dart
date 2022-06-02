part of 'cell_service.dart';

typedef GridCellContext = _GridCellContext<String, String>;
typedef GridSelectOptionCellContext = _GridCellContext<SelectOptionCellData, String>;
typedef GridDateCellContext = _GridCellContext<DateCellData, CalendarData>;
typedef GridURLCellContext = _GridCellContext<URLCellData, String>;

class GridCellContextBuilder {
  final GridCellCache _cellCache;
  final GridCell _gridCell;
  GridCellContextBuilder({
    required GridCellCache cellCache,
    required GridCell gridCell,
  })  : _cellCache = cellCache,
        _gridCell = gridCell;

  _GridCellContext build() {
    switch (_gridCell.field.fieldType) {
      case FieldType.Checkbox:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: StringCellDataParser(),
        );
        return GridCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.DateTime:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: DateCellDataParser(),
          config: const GridCellDataConfig(reloadOnFieldChanged: true),
        );

        return GridDateCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: DateCellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.Number:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: StringCellDataParser(),
          config: const GridCellDataConfig(reloadOnCellChanged: true, reloadOnFieldChanged: true),
        );
        return GridCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.RichText:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: StringCellDataParser(),
        );
        return GridCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: SelectOptionCellDataParser(),
          config: const GridCellDataConfig(reloadOnFieldChanged: true),
        );

        return GridSelectOptionCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );

      case FieldType.URL:
        final cellDataLoader = GridCellDataLoader(
          gridCell: _gridCell,
          parser: URLCellDataParser(),
        );
        return GridURLCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
    }
    throw UnimplementedError;
  }
}

// T: the type of the CellData
// D: the type of the data that will be save to disk
// ignore: must_be_immutable
class _GridCellContext<T, D> extends Equatable {
  final GridCell gridCell;
  final GridCellCache cellCache;
  final GridCellCacheKey _cacheKey;
  final IGridCellDataLoader<T> cellDataLoader;
  final _GridCellDataPersistence<D> cellDataPersistence;
  final FieldService _fieldService;

  late final CellListener _cellListener;
  late final ValueNotifier<T?>? _cellDataNotifier;
  bool isListening = false;
  VoidCallback? _onFieldChangedFn;
  Timer? _loadDataOperation;
  Timer? _saveDataOperation;

  _GridCellContext({
    required this.gridCell,
    required this.cellCache,
    required this.cellDataLoader,
    required this.cellDataPersistence,
  })  : _fieldService = FieldService(gridId: gridCell.gridId, fieldId: gridCell.field.id),
        _cacheKey = GridCellCacheKey(objectId: gridCell.rowId, fieldId: gridCell.field.id);

  _GridCellContext<T, D> clone() {
    return _GridCellContext(
        gridCell: gridCell,
        cellDataLoader: cellDataLoader,
        cellCache: cellCache,
        cellDataPersistence: cellDataPersistence);
  }

  String get gridId => gridCell.gridId;

  String get rowId => gridCell.rowId;

  String get cellId => gridCell.rowId + gridCell.field.id;

  String get fieldId => gridCell.field.id;

  Field get field => gridCell.field;

  FieldType get fieldType => gridCell.field.fieldType;

  VoidCallback? startListening({required void Function(T?) onCellChanged}) {
    if (isListening) {
      Log.error("Already started. It seems like you should call clone first");
      return null;
    }

    isListening = true;
    _cellDataNotifier = ValueNotifier(cellCache.get(_cacheKey));
    _cellListener = CellListener(rowId: gridCell.rowId, fieldId: gridCell.field.id);
    _cellListener.start(onCellChanged: (result) {
      result.fold(
        (_) => _loadData(),
        (err) => Log.error(err),
      );
    });

    if (cellDataLoader.config.reloadOnFieldChanged) {
      _onFieldChangedFn = () {
        _loadData();
      };
      cellCache.addFieldListener(_cacheKey, _onFieldChangedFn!);
    }

    onCellChangedFn() {
      onCellChanged(_cellDataNotifier?.value);

      if (cellDataLoader.config.reloadOnCellChanged) {
        _loadData();
      }
    }

    _cellDataNotifier?.addListener(onCellChangedFn);
    return onCellChangedFn;
  }

  void removeListener(VoidCallback fn) {
    _cellDataNotifier?.removeListener(fn);
  }

  T? getCellData({bool loadIfNoCache = true}) {
    final data = cellCache.get(_cacheKey);
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
        final result = await cellDataPersistence.save(data);
        if (resultCallback != null) {
          resultCallback(result);
        }
      });
    } else {
      final result = await cellDataPersistence.save(data);
      if (resultCallback != null) {
        resultCallback(result);
      }
    }
  }

  void _loadData() {
    _loadDataOperation?.cancel();
    _loadDataOperation = Timer(const Duration(milliseconds: 10), () {
      cellDataLoader.loadData().then((data) {
        _cellDataNotifier?.value = data;
        cellCache.insert(GridCellCacheData(key: _cacheKey, object: data));
      });
    });
  }

  void dispose() {
    _cellListener.stop();
    _loadDataOperation?.cancel();
    _saveDataOperation?.cancel();

    if (_onFieldChangedFn != null) {
      cellCache.removeFieldListener(_cacheKey, _onFieldChangedFn!);
      _onFieldChangedFn = null;
    }
  }

  @override
  List<Object> get props => [cellCache.get(_cacheKey) ?? "", cellId];
}
