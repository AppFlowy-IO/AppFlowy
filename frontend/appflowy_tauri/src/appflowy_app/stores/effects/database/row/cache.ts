import {
  RowPB,
  InsertedRowPB,
  UpdatedRowPB,
  RowIdPB,
  OptionalRowPB,
} from '../../../../../services/backend/models/flowy-database/row_entities';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { FieldInfo } from '../field/controller';
import { CellCache, CellCacheKey } from '../cell/cache';
import {
  RowsChangesetPB,
  RowsVisibilityChangesetPB,
} from '../../../../../services/backend/models/flowy-database/view_entities';
import { CellIdentifier } from '../cell/backend_service';
import { ReorderSingleRowPB } from '../../../../../services/backend/models/flowy-database/sort_entities';
import { DatabaseEventGetRow } from '../../../../../services/backend/events/flowy-database';
import { None, Option, Some } from 'ts-results';
import { Log } from '../../../../utils/log';

type CellByFieldId = Map<string, CellIdentifier>;

export class RowCache {
  private _rowList: RowList;
  private _cellCache: CellCache;
  private _notifier: RowChangeNotifier;

  constructor(public readonly viewId: string, private readonly getFieldInfos: () => readonly FieldInfo[]) {
    this._rowList = new RowList();
    this._cellCache = new CellCache(viewId);
    this._notifier = new RowChangeNotifier();
  }

  get rows(): readonly RowInfo[] {
    return this._rowList.rows;
  }

  getCellCache = () => {
    return this._cellCache;
  };

  loadCells = async (rowId: string): Promise<CellByFieldId> => {
    const opRow = this._rowList.getRow(rowId);
    if (opRow.some) {
      return this._toCellMap(opRow.val.row.id, this.getFieldInfos());
    } else {
      const rowResult = await this._loadRow(rowId);
      if (rowResult.ok) {
        this._refreshRow(rowResult.val);
        return this._toCellMap(rowId, this.getFieldInfos());
      } else {
        Log.error(rowResult.val);
        return new Map();
      }
    }
  };

  subscribeOnRowsChanged = (callback: (reason: RowChangedReason, cellMap?: Map<string, CellIdentifier>) => void) => {
    return this._notifier.observer.subscribe((change) => {
      if (change.rowId !== undefined) {
        callback(change.reason, this._toCellMap(change.rowId, this.getFieldInfos()));
      } else {
        callback(change.reason);
      }
    });
  };

  onFieldUpdated = (fieldInfo: FieldInfo) => {
    // Remove the cell data if the corresponding field was changed
    this._cellCache.removeWithFieldId(fieldInfo.field.id);
  };

  onNumberOfFieldsUpdated = () => {
    this._notifier.withChange(RowChangedReason.FieldDidChanged);
  };

  initializeRows = (rows: RowPB[]) => {
    rows.forEach((rowPB) => {
      this._rowList.push(this._toRowInfo(rowPB));
    });
    this._notifier.withChange(RowChangedReason.ReorderRows);
  };

  applyRowsChanged = (changeset: RowsChangesetPB) => {
    this._deleteRows(changeset.deleted_rows);
    this._insertRows(changeset.inserted_rows);
    this._updateRows(changeset.updated_rows);
  };

  applyRowsVisibility = (changeset: RowsVisibilityChangesetPB) => {
    this._hideRows(changeset.invisible_rows);
    this._displayRows(changeset.visible_rows);
  };

  applyReorderRows = (rowIds: string[]) => {
    this._rowList.reorderByRowIds(rowIds);
    this._notifier.withChange(RowChangedReason.ReorderRows);
  };

  applyReorderSingleRow = (reorderRow: ReorderSingleRowPB) => {
    const rowInfo = this._rowList.getRow(reorderRow.row_id);
    if (rowInfo !== undefined) {
      this._rowList.move({ rowId: reorderRow.row_id, fromIndex: reorderRow.old_index, toIndex: reorderRow.new_index });
      this._notifier.withChange(RowChangedReason.ReorderSingleRow, reorderRow.row_id);
    }
  };

  private _refreshRow = (opRow: OptionalRowPB) => {
    if (!opRow.has_row) {
      return;
    }
    const updatedRow = opRow.row;
    const option = this._rowList.getRowWithIndex(updatedRow.id);
    if (option.some) {
      const { rowInfo, index } = option.val;
      const updatedRowInfo = new RowInfo(rowInfo.viewId, rowInfo.fieldInfos, updatedRow);
      this._rowList.remove(rowInfo.row.id);
      this._rowList.insert(index, updatedRowInfo);
    } else {
      const newRowInfo = new RowInfo(this.viewId, this.getFieldInfos(), updatedRow);
      this._rowList.push(newRowInfo);
    }
  };

  private _loadRow = (rowId: string) => {
    const payload = RowIdPB.fromObject({ view_id: this.viewId, row_id: rowId });
    return DatabaseEventGetRow(payload);
  };

  private _deleteRows = (rowIds: string[]) => {
    rowIds.forEach((rowId) => {
      const deletedRow = this._rowList.remove(rowId);
      if (deletedRow !== undefined) {
        this._notifier.withChange(RowChangedReason.Delete, deletedRow.rowInfo.row.id);
      }
    });
  };

  private _insertRows = (rows: InsertedRowPB[]) => {
    rows.forEach((insertedRow) => {
      const rowInfo = this._toRowInfo(insertedRow.row);
      const insertedIndex = this._rowList.insert(insertedRow.index, rowInfo);
      if (insertedIndex !== undefined) {
        this._notifier.withChange(RowChangedReason.Insert, insertedIndex.rowId);
      }
    });
  };

  private _updateRows = (updatedRows: UpdatedRowPB[]) => {
    if (updatedRows.length === 0) {
      return;
    }

    const rowInfos: RowInfo[] = [];
    updatedRows.forEach((updatedRow) => {
      updatedRow.field_ids.forEach((fieldId) => {
        const key = new CellCacheKey(fieldId, updatedRow.row.id);
        this._cellCache.remove(key);
      });

      rowInfos.push(this._toRowInfo(updatedRow.row));
    });

    const updatedIndexs = this._rowList.insertRows(rowInfos);
    updatedIndexs.forEach((row) => {
      this._notifier.withChange(RowChangedReason.Update, row.rowId);
    });
  };

  private _hideRows = (rowIds: string[]) => {
    rowIds.forEach((rowId) => {
      const deletedRow = this._rowList.remove(rowId);
      if (deletedRow !== undefined) {
        this._notifier.withChange(RowChangedReason.Delete, deletedRow.rowInfo.row.id);
      }
    });
  };

  private _displayRows = (insertedRows: InsertedRowPB[]) => {
    insertedRows.forEach((insertedRow) => {
      const insertedIndex = this._rowList.insert(insertedRow.index, this._toRowInfo(insertedRow.row));

      if (insertedIndex !== undefined) {
        this._notifier.withChange(RowChangedReason.Insert, insertedIndex.rowId);
      }
    });
  };

  dispose = async () => {
    this._notifier.dispose();
  };

  private _toRowInfo = (rowPB: RowPB) => {
    return new RowInfo(this.viewId, this.getFieldInfos(), rowPB);
  };

  private _toCellMap = (rowId: string, fieldInfos: readonly FieldInfo[]): CellByFieldId => {
    const cellIdentifierByFieldId: Map<string, CellIdentifier> = new Map();

    fieldInfos.forEach((fieldInfo) => {
      const identifier = new CellIdentifier(this.viewId, rowId, fieldInfo.field.id, fieldInfo.field.field_type);
      cellIdentifierByFieldId.set(fieldInfo.field.id, identifier);
    });

    return cellIdentifierByFieldId;
  };
}

class RowList {
  _rowInfos: RowInfo[] = [];
  _rowInfoByRowId: Map<string, RowInfo> = new Map();

  get rows(): readonly RowInfo[] {
    return this._rowInfos;
  }

  getRow = (rowId: string): Option<RowInfo> => {
    const rowInfo = this._rowInfoByRowId.get(rowId);
    if (rowInfo === undefined) {
      return None;
    } else {
      return Some(rowInfo);
    }
  };

  getRowWithIndex = (rowId: string): Option<{ rowInfo: RowInfo; index: number }> => {
    const rowInfo = this._rowInfoByRowId.get(rowId);
    if (rowInfo !== undefined) {
      const index = this._rowInfos.indexOf(rowInfo, 0);
      return Some({ rowInfo: rowInfo, index: index });
    }
    return None;
  };

  indexOfRow = (rowId: string): number => {
    const rowInfo = this._rowInfoByRowId.get(rowId);
    if (rowInfo !== undefined) {
      return this._rowInfos.indexOf(rowInfo, 0);
    }
    return -1;
  };

  push = (rowInfo: RowInfo) => {
    const index = this.indexOfRow(rowInfo.row.id);
    if (index !== -1) {
      this._rowInfos.splice(index, 1, rowInfo);
    } else {
      this._rowInfos.push(rowInfo);
    }

    this._rowInfoByRowId.set(rowInfo.row.id, rowInfo);
  };

  remove = (rowId: string): DeletedRow | undefined => {
    const result = this.getRowWithIndex(rowId);
    if (result.some) {
      const { rowInfo, index } = result.val;
      this._rowInfoByRowId.delete(rowInfo.row.id);
      this._rowInfos.splice(index, 1);
      return new DeletedRow(index, rowInfo);
    } else {
      return undefined;
    }
  };

  insert = (insertIndex: number, newRowInfo: RowInfo): InsertedRow | undefined => {
    const rowId = newRowInfo.row.id;
    // Calibrate where to insert
    let insertedIndex = insertIndex;
    if (this._rowInfos.length <= insertedIndex) {
      insertedIndex = this._rowInfos.length;
    }
    const result = this.getRowWithIndex(rowId);

    if (result.some) {
      const { index } = result.val;
      // remove the old row info
      this._rowInfos.splice(index, 1);
      // insert the new row info to the insertedIndex
      this._rowInfos.splice(insertedIndex, 0, newRowInfo);
      this._rowInfoByRowId.set(rowId, newRowInfo);
      return undefined;
    } else {
      this._rowInfos.splice(insertedIndex, 0, newRowInfo);
      this._rowInfoByRowId.set(rowId, newRowInfo);
      return new InsertedRow(insertedIndex, rowId);
    }
  };

  insertRows = (rowInfos: RowInfo[]) => {
    const map = new Map<string, InsertedRow>();
    rowInfos.forEach((rowInfo) => {
      const index = this.indexOfRow(rowInfo.row.id);
      if (index !== -1) {
        this._rowInfos.splice(index, 1, rowInfo);
        this._rowInfoByRowId.set(rowInfo.row.id, rowInfo);

        map.set(rowInfo.row.id, new InsertedRow(index, rowInfo.row.id));
      }
    });
    return map;
  };

  move = (params: { rowId: string; fromIndex: number; toIndex: number }) => {
    const currentIndex = this.indexOfRow(params.rowId);
    if (currentIndex !== -1 && currentIndex !== params.toIndex) {
      const rowInfo = this.remove(params.rowId)?.rowInfo;
      if (rowInfo !== undefined) {
        this.insert(params.toIndex, rowInfo);
      }
    }
  };

  reorderByRowIds = (rowIds: string[]) => {
    // remove all the elements
    this._rowInfos = [];
    rowIds.forEach((rowId) => {
      const rowInfo = this._rowInfoByRowId.get(rowId);
      if (rowInfo !== undefined) {
        this._rowInfos.push(rowInfo);
      }
    });
  };

  includes = (rowId: string): boolean => {
    return this._rowInfoByRowId.has(rowId);
  };
}

export class RowInfo {
  constructor(
    public readonly viewId: string,
    public readonly fieldInfos: readonly FieldInfo[],
    public readonly row: RowPB
  ) {}
}

export class DeletedRow {
  constructor(public readonly index: number, public readonly rowInfo: RowInfo) {}
}

export class InsertedRow {
  constructor(public readonly index: number, public readonly rowId: string) {}
}

export class RowChanged {
  constructor(public readonly reason: RowChangedReason, public readonly rowId?: string) {}
}

// eslint-disable-next-line no-shadow
export enum RowChangedReason {
  Insert,
  Delete,
  Update,
  Initial,
  FieldDidChanged,
  ReorderRows,
  ReorderSingleRow,
}

export class RowChangeNotifier extends ChangeNotifier<RowChanged> {
  _currentChanged = new RowChanged(RowChangedReason.Initial);

  withChange = (reason: RowChangedReason, rowId?: string) => {
    const newChange = new RowChanged(reason, rowId);
    if (this._currentChanged !== newChange) {
      this._currentChanged = newChange;
      this.notify(this._currentChanged);
    }
  };

  dispose = () => {
    this.unsubscribe();
  };
}
