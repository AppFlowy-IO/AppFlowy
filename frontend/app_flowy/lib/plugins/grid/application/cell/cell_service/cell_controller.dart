part of 'cell_service.dart';

typedef GridTextCellController = GridCellController<String, String>;
typedef GridCheckboxCellController = GridCellController<String, String>;
typedef GridNumberCellController = GridCellController<String, String>;
typedef GridSelectOptionCellController
    = GridCellController<SelectOptionCellDataPB, String>;
typedef GridChecklistCellController
    = GridCellController<SelectOptionCellDataPB, String>;
typedef GridDateCellController
    = GridCellController<DateCellDataPB, CalendarData>;
typedef GridURLCellController = GridCellController<URLCellDataPB, String>;

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

  GridCellController build() {
    final cellFieldNotifier = delegate.buildFieldNotifier();
    switch (_cellId.fieldType) {
      case FieldType.Checkbox:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: StringCellDataParser(),
        );
        return GridTextCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
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
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );
      case FieldType.RichText:
        final cellDataLoader = GridCellDataLoader(
          cellId: _cellId,
          parser: StringCellDataParser(),
        );
        return GridTextCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          fieldNotifier: cellFieldNotifier,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
      case FieldType.Checklist:
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
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
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
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
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
class GridCellController<T, D> extends Equatable {
  final GridCellIdentifier cellId;
  final GridCellCache _cellsCache;
  final GridCellCacheKey _cacheKey;
  final FieldService _fieldService;
  final GridCellFieldNotifier _fieldNotifier;
  final GridCellDataLoader<T> _cellDataLoader;
  final GridCellDataPersistence<D> _cellDataPersistence;

  CellListener? _cellListener;
  CellDataNotifier<T?>? _cellDataNotifier;

  bool isListening = false;
  VoidCallback? _onFieldChangedFn;
  Timer? _loadDataOperation;
  Timer? _saveDataOperation;
  bool _isDispose = false;

  GridCellController({
    required this.cellId,
    required GridCellCache cellCache,
    required GridCellFieldNotifier fieldNotifier,
    required GridCellDataLoader<T> cellDataLoader,
    required GridCellDataPersistence<D> cellDataPersistence,
  })  : _cellsCache = cellCache,
        _cellDataLoader = cellDataLoader,
        _cellDataPersistence = cellDataPersistence,
        _fieldNotifier = fieldNotifier,
        _fieldService = FieldService(
          gridId: cellId.gridId,
          fieldId: cellId.fieldInfo.id,
        ),
        _cacheKey = GridCellCacheKey(
          rowId: cellId.rowId,
          fieldId: cellId.fieldInfo.id,
        );

  String get gridId => cellId.gridId;

  String get rowId => cellId.rowId;

  String get fieldId => cellId.fieldInfo.id;

  FieldInfo get fieldInfo => cellId.fieldInfo;

  FieldType get fieldType => cellId.fieldInfo.fieldType;

  /// Listen on the cell content or field changes
  ///
  /// An optional [listenWhenOnCellChanged] can be implemented for more
  ///  granular control over when [listener] is called.
  /// [listenWhenOnCellChanged] will be invoked on each [onCellChanged]
  /// get called.
  /// [listenWhenOnCellChanged] takes the previous `value` and current
  /// `value` and must return a [bool] which determines whether or not
  ///  the [onCellChanged] function will be invoked.
  /// [onCellChanged] is optional and if omitted, it will default to `true`.
  ///
  VoidCallback? startListening({
    required void Function(T?) onCellChanged,
    bool Function(T? oldValue, T? newValue)? listenWhenOnCellChanged,
    VoidCallback? onCellFieldChanged,
  }) {
    if (isListening) {
      Log.error("Already started. It seems like you should call clone first");
      return null;
    }
    isListening = true;

    _cellDataNotifier = CellDataNotifier(
      value: _cellsCache.get(_cacheKey),
      listenWhen: listenWhenOnCellChanged,
    );
    _cellListener =
        CellListener(rowId: cellId.rowId, fieldId: cellId.fieldInfo.id);

    /// 1.Listen on user edit event and load the new cell data if needed.
    /// For example:
    ///  user input: 12
    ///  cell display: $12
    _cellListener?.start(onCellChanged: (result) {
      result.fold(
        (_) {
          _cellsCache.remove(_cacheKey);
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

  /// Return the TypeOptionPB that can be parsed into corresponding class using the [parser].
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
  void saveCellData(
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
          _cellsCache.insert(_cacheKey, GridCell(object: data));
        } else {
          _cellsCache.remove(_cacheKey);
        }

        _cellDataNotifier?.value = data;
      });
    });
  }

  Future<void> dispose() async {
    if (_isDispose) {
      Log.error("$this should only dispose once");
      return;
    }
    _isDispose = true;
    await _cellListener?.stop();
    _loadDataOperation?.cancel();
    _saveDataOperation?.cancel();
    _cellDataNotifier?.dispose();
    _cellDataNotifier = null;

    if (_onFieldChangedFn != null) {
      _fieldNotifier.unregister(_cacheKey, _onFieldChangedFn!);
      await _fieldNotifier.dispose();
      _onFieldChangedFn = null;
    }
  }

  @override
  List<Object> get props =>
      [_cellsCache.get(_cacheKey) ?? "", cellId.rowId + cellId.fieldInfo.id];
}

class GridCellFieldNotifierImpl extends IGridCellFieldNotifier {
  final GridFieldController _fieldController;
  OnReceiveUpdateFields? _onChangesetFn;

  GridCellFieldNotifierImpl(GridFieldController cache)
      : _fieldController = cache;

  @override
  void onCellDispose() {
    if (_onChangesetFn != null) {
      _fieldController.removeListener(onChangesetListener: _onChangesetFn!);
      _onChangesetFn = null;
    }
  }

  @override
  void onCellFieldChanged(void Function(FieldInfo) callback) {
    _onChangesetFn = (List<FieldInfo> filedInfos) {
      for (final field in filedInfos) {
        callback(field);
      }
    };
    _fieldController.addListener(
      onFieldsUpdated: _onChangesetFn,
    );
  }
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
