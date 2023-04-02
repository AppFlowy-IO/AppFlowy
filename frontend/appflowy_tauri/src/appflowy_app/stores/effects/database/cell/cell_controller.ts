import { CellIdentifier } from './cell_bd_svc';
import { CellCache, CellCacheKey } from './cell_cache';
import { CellDataLoader } from './data_parser';
import { CellDataPersistence } from './data_persistence';
import { FieldBackendService, TypeOptionParser } from '../field/field_bd_svc';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { CellObserver } from './cell_observer';
import { Log } from '../../../../utils/log';
import { Err, None, Ok, Option, Some } from 'ts-results';
import { DatabaseFieldObserver } from '../field/field_observer';

type Callbacks<T> = { onCellChanged: (value: Option<T>) => void; onFieldChanged?: () => void };

export class CellController<T, D> {
  private fieldBackendService: FieldBackendService;
  private cellDataNotifier: CellDataNotifier<T>;
  private cellObserver: CellObserver;
  private readonly cacheKey: CellCacheKey;
  private readonly fieldNotifier: DatabaseFieldObserver;
  private subscribeCallbacks?: Callbacks<T>;

  constructor(
    public readonly cellIdentifier: CellIdentifier,
    private readonly cellCache: CellCache,
    private readonly cellDataLoader: CellDataLoader<T>,
    private readonly cellDataPersistence: CellDataPersistence<D>
  ) {
    this.fieldBackendService = new FieldBackendService(cellIdentifier.viewId, cellIdentifier.fieldId);
    this.cacheKey = new CellCacheKey(cellIdentifier.fieldId, cellIdentifier.rowId);
    this.cellDataNotifier = new CellDataNotifier(cellCache.get<T>(this.cacheKey));
    this.cellObserver = new CellObserver(cellIdentifier.rowId, cellIdentifier.fieldId);
    this.fieldNotifier = new DatabaseFieldObserver(cellIdentifier.fieldId);
    void this.cellObserver.subscribe({
      /// 1.Listen on user edit event and load the new cell data if needed.
      /// For example:
      ///  user input: 12
      ///  cell display: $12
      onCellChanged: async () => {
        this.cellCache.remove(this.cacheKey);
        await this._loadCellData();
      },
    });

    /// 2.Listen on the field event and load the cell data if needed.
    void this.fieldNotifier.subscribe({
      onFieldChanged: () => {
        this.subscribeCallbacks?.onFieldChanged?.();
        /// reloadOnFieldChanged should be true if you need to load the data when the corresponding field is changed
        /// For example:
        ///   ￥12 -> $12
        if (this.cellDataLoader.reloadOnFieldChanged) {
          void this._loadCellData();
        }
      },
    });
  }

  subscribeChanged = (callbacks: Callbacks<T>) => {
    this.subscribeCallbacks = callbacks;
    this.cellDataNotifier.observer.subscribe((cellData) => {
      if (cellData !== null) {
        callbacks.onCellChanged(Some(cellData));
      }
    });
  };

  getTypeOption = async <P extends TypeOptionParser<PD>, PD>(parser: P) => {
    const result = await this.fieldBackendService.getTypeOptionData(this.cellIdentifier.fieldType);
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

  /// Return the cell data immediately if it exists in the cache
  /// Otherwise, it will load the cell data from the backend. The
  /// subscribers of the [onCellChanged] will get noticed
  getCellData = async (): Promise<Option<T>> => {
    const cellData = this.cellCache.get<T>(this.cacheKey);
    if (cellData.none) {
      await this._loadCellData();
      return this.cellCache.get<T>(this.cacheKey);
    }
    return cellData;
  };

  private _loadCellData = () => {
    return this.cellDataLoader.loadData().then((result) => {
      if (result.ok) {
        const cellData = result.val;
        if (cellData.some) {
          this.cellCache.insert(this.cacheKey, cellData.val);
          this.cellDataNotifier.cellData = cellData;
        }
      } else {
        this.cellCache.remove(this.cacheKey);
        this.cellDataNotifier.cellData = None;
      }
    });
  };

  dispose = async () => {
    this.cellDataNotifier.unsubscribe();
    await this.cellObserver.unsubscribe();
    await this.fieldNotifier.unsubscribe();
  };
}

class CellDataNotifier<T> extends ChangeNotifier<T> {
  _cellData: Option<T>;

  constructor(cellData: Option<T>) {
    super();
    this._cellData = cellData;
  }

  set cellData(data: Option<T>) {
    if (this._cellData !== data) {
      this._cellData = data;

      if (this._cellData.some) {
        this.notify(this._cellData.val);
      }
    }
  }

  get cellData(): Option<T> {
    return this._cellData;
  }
}
