import { CellIdentifier } from './cell_bd_svc';
import { CellCache, CellCacheKey } from './cell_cache';
import { FieldController } from '../field/field_controller';
import { CellDataLoader } from './data_parser';
import { CellDataPersistence } from './data_persistence';
import { FieldBackendService, TypeOptionParser } from '../field/field_bd_svc';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { CellObserver } from './cell_observer';
import { Log } from '../../../../utils/log';
import { Err, None, Ok, Option, Some } from 'ts-results';

export abstract class CellFieldNotifier {
  abstract subscribeOnFieldChanged(callback: () => void): void;
}

export class CellController<T, D> {
  private _fieldBackendService: FieldBackendService;
  private _cellDataNotifier: CellDataNotifier<Option<T>>;
  private _cellObserver: CellObserver;
  private _cacheKey: CellCacheKey;

  constructor(
    public readonly cellIdentifier: CellIdentifier,
    private readonly cellCache: CellCache,
    private readonly fieldNotifier: CellFieldNotifier,
    private readonly cellDataLoader: CellDataLoader<T>,
    private readonly cellDataPersistence: CellDataPersistence<D>
  ) {
    this._fieldBackendService = new FieldBackendService(cellIdentifier.viewId, cellIdentifier.fieldId);
    this._cacheKey = new CellCacheKey(cellIdentifier.rowId, cellIdentifier.fieldId);
    this._cellDataNotifier = new CellDataNotifier(cellCache.get<T>(this._cacheKey));
    this._cellObserver = new CellObserver(cellIdentifier.rowId, cellIdentifier.fieldId);
    this._cellObserver.subscribe({
      /// 1.Listen on user edit event and load the new cell data if needed.
      /// For example:
      ///  user input: 12
      ///  cell display: $12
      onCellChanged: async () => {
        this.cellCache.remove(this._cacheKey);
        await this._loadCellData();
      },
    });
  }

  subscribeChanged = (callbacks: { onCellChanged: (value: Option<T>) => void; onFieldChanged?: () => void }) => {
    /// 2.Listen on the field event and load the cell data if needed.
    this.fieldNotifier.subscribeOnFieldChanged(async () => {
      callbacks.onFieldChanged?.();

      /// reloadOnFieldChanged should be true if you need to load the data when the corresponding field is changed
      /// For example:
      ///   ￥12 -> $12
      if (this.cellDataLoader.reloadOnFieldChanged) {
        await this._loadCellData();
      }
    });

    this._cellDataNotifier.observer.subscribe((cellData) => {
      if (cellData !== null) {
        callbacks.onCellChanged(cellData);
      }
    });
  };

  getTypeOption = async <P extends TypeOptionParser<PD>, PD>(parser: P) => {
    const result = await this._fieldBackendService.getTypeOptionData(this.cellIdentifier.fieldType);
    if (result.ok) {
      return Ok(parser.fromBuffer(result.val.type_option_data));
    } else {
      return Err(result.val);
    }
  };

  saveCellData = async (data: D) => {
    const result = await this.cellDataPersistence.save(data);
    if (result.err) {
      Log.error(result.val);
    }
  };

  /// Return the cell data if it exists in the cache
  /// If the cell data is not exist, it will load the cell
  /// data from the backend and then the [onCellChanged] will
  /// get called
  getCellData = (): Option<T> => {
    const cellData = this.cellCache.get<T>(this._cacheKey);
    if (cellData.none) {
      void this._loadCellData();
    }
    return cellData;
  };

  private _loadCellData = () => {
    return this.cellDataLoader.loadData().then((result) => {
      if (result.ok && result.val !== undefined) {
        this.cellCache.insert(this._cacheKey, result.val);
        this._cellDataNotifier.cellData = Some(result.val);
      } else {
        this.cellCache.remove(this._cacheKey);
        this._cellDataNotifier.cellData = None;
      }
    });
  };
}

export class CellFieldNotifierImpl extends CellFieldNotifier {
  constructor(private readonly fieldController: FieldController) {
    super();
  }

  subscribeOnFieldChanged(callback: () => void): void {
    this.fieldController.subscribeOnFieldsChanged(callback);
  }
}

class CellDataNotifier<T> extends ChangeNotifier<T | null> {
  _cellData: T | null;

  constructor(cellData: T) {
    super();
    this._cellData = cellData;
  }

  set cellData(data: T | null) {
    if (this._cellData !== data) {
      this._cellData = data;
      this.notify(this._cellData);
    }
  }

  get cellData(): T | null {
    return this._cellData;
  }
}
