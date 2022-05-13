part of 'cell_service.dart';

typedef GridCellContext = _GridCellContext<Cell, String>;
typedef GridSelectOptionCellContext = _GridCellContext<SelectOptionCellData, String>;
typedef GridDateCellContext = _GridCellContext<DateCellData, DateCellPersistenceData>;

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
        return GridCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: CellDataLoader(gridCell: _gridCell),
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.DateTime:
        return GridDateCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: DateCellDataLoader(gridCell: _gridCell),
          cellDataPersistence: DateCellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.Number:
        return GridCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: CellDataLoader(gridCell: _gridCell, reloadOnCellChanged: true),
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.RichText:
        return GridCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: CellDataLoader(gridCell: _gridCell),
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        return GridSelectOptionCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: SelectOptionCellDataLoader(gridCell: _gridCell),
          cellDataPersistence: CellDataPersistence(gridCell: _gridCell),
        );
      default:
        throw UnimplementedError;
    }
  }
}

// ignore: must_be_immutable
class _GridCellContext<T, D> extends Equatable {
  final GridCell gridCell;
  final GridCellCache cellCache;
  final GridCellCacheKey _cacheKey;
  final _GridCellDataLoader<T> cellDataLoader;
  final _GridCellDataPersistence<D> cellDataPersistence;
  final FieldService _fieldService;

  late final CellListener _cellListener;
  late final ValueNotifier<T?> _cellDataNotifier;
  bool isListening = false;
  VoidCallback? _onFieldChangedFn;
  Timer? _delayOperation;

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

  VoidCallback? startListening({required void Function(T) onCellChanged}) {
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
      final value = _cellDataNotifier.value;
      if (value is T) {
        onCellChanged(value);
      }

      if (cellDataLoader.config.reloadOnCellChanged) {
        _loadData();
      }
    }

    _cellDataNotifier.addListener(onCellChangedFn);
    return onCellChangedFn;
  }

  void removeListener(VoidCallback fn) {
    _cellDataNotifier.removeListener(fn);
  }

  T? getCellData() {
    final data = cellCache.get(_cacheKey);
    if (data == null) {
      _loadData();
    }
    return data;
  }

  Future<Either<List<int>, FlowyError>> getTypeOptionData() {
    return _fieldService.getTypeOptionData(fieldType: fieldType);
  }

  Future<Option<FlowyError>> saveCellData(D data) {
    return cellDataPersistence.save(data);
  }

  void _loadData() {
    _delayOperation?.cancel();
    _delayOperation = Timer(const Duration(milliseconds: 10), () {
      cellDataLoader.loadData().then((data) {
        _cellDataNotifier.value = data;
        cellCache.insert(GridCellCacheData(key: _cacheKey, object: data));
      });
    });
  }

  void dispose() {
    _delayOperation?.cancel();

    if (_onFieldChangedFn != null) {
      cellCache.removeFieldListener(_cacheKey, _onFieldChangedFn!);
      _onFieldChangedFn = null;
    }
  }

  @override
  List<Object> get props => [cellCache.get(_cacheKey) ?? "", cellId];
}
