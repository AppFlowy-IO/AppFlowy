import { RowPB, InsertedRowPB, UpdatedRowPB } from '../../../../../services/backend/models/flowy-database/row_entities';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { FieldInfo } from '../field/controller';
import { CellCache, CellCacheKey } from '../cell/cache';
import {
  ViewRowsChangesetPB,
  ViewRowsVisibilityChangesetPB,
} from '../../../../../services/backend/models/flowy-database/view_entities';
import { CellIdentifier } from '../cell/backend_service';
import { ReorderSingleRowPB } from '../../../../../services/backend/models/flowy-database/sort_entities';

export class RowCache {
  _rowList: RowList;
  _cellCache: CellCache;
  _notifier: RowChangeNotifier;

  constructor(public readonly viewId: string, private readonly getFieldInfos: () => readonly FieldInfo[]) {
    this._rowList = new RowList();
    this._cellCache = new CellCache(viewId);
    this._notifier = new RowChangeNotifier();
  }

  get rows(): readonly RowInfo[] {
    return this._rowList.rows;
  }

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
  };

  applyRowsChanged = (changeset: ViewRowsChangesetPB) => {
    this._deleteRows(changeset.deleted_rows);
    this._insertRows(changeset.inserted_rows);
    this._updateRows(changeset.updated_rows);
  };

  applyRowsVisibility = (changeset: ViewRowsVisibilityChangesetPB) => {
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

  _deleteRows = (rowIds: string[]) => {
    rowIds.forEach((rowId) => {
      const deletedRow = this._rowList.remove(rowId);
      if (deletedRow !== undefined) {
        this._notifier.withChange(RowChangedReason.Delete, deletedRow.rowInfo.row.id);
      }
    });
  };

  _insertRows = (rows: InsertedRowPB[]) => {
    rows.forEach((insertedRow) => {
      const rowInfo = this._toRowInfo(insertedRow.row);
      const insertedIndex = this._rowList.insert(insertedRow.index, rowInfo);
      if (insertedIndex !== undefined) {
        this._notifier.withChange(RowChangedReason.Insert, insertedIndex.rowId);
      }
    });
  };

  _updateRows = (updatedRows: UpdatedRowPB[]) => {
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

  _hideRows = (rowIds: string[]) => {
    rowIds.forEach((rowId) => {
      const deletedRow = this._rowList.remove(rowId);
      if (deletedRow !== undefined) {
        this._notifier.withChange(RowChangedReason.Delete, deletedRow.rowInfo.row.id);
      }
    });
  };

  _displayRows = (insertedRows: InsertedRowPB[]) => {
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

  _toRowInfo = (rowPB: RowPB) => {
    return new RowInfo(this.viewId, this.getFieldInfos(), rowPB);
  };

  _toCellMap = (rowId: string, fieldInfos: readonly FieldInfo[]): Map<string, CellIdentifier> => {
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

  getRow = (rowId: string) => {
    return this._rowInfoByRowId.get(rowId);
  };

  getRowWithIndex = (rowId: string): { rowInfo: RowInfo; index: number } | undefined => {
    const rowInfo = this._rowInfoByRowId.get(rowId);
    if (rowInfo !== undefined) {
      const index = this._rowInfos.indexOf(rowInfo, 0);
      return { rowInfo: rowInfo, index: index };
    }
    return undefined;
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
    if (result !== undefined) {
      this._rowInfoByRowId.delete(result.rowInfo.row.id);
      this._rowInfos.splice(result.index, 1);
      return new DeletedRow(result.index, result.rowInfo);
    } else {
      return undefined;
    }
  };

  insert = (index: number, newRowInfo: RowInfo): InsertedRow | undefined => {
    const rowId = newRowInfo.row.id;
    // Calibrate where to insert
    let insertedIndex = index;
    if (this._rowInfos.length <= insertedIndex) {
      insertedIndex = this._rowInfos.length;
    }
    const result = this.getRowWithIndex(rowId);

    if (result !== undefined) {
      // remove the old row info
      this._rowInfos.splice(result.index, 1);
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
