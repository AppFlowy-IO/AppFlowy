/* eslint-disable @typescript-eslint/no-explicit-any */
import { None, Option, Some } from 'ts-results';

export class CellCacheKey {
  constructor(public readonly fieldId: string, public readonly rowId: string) {}
}

type CellDataByRowId = Map<string, any>;

export class CellCache {
  private cellDataByFieldId = new Map<string, CellDataByRowId>();

  constructor(public readonly databaseId: string) {}

  remove = (key: CellCacheKey) => {
    const cellDataByRowId = this.cellDataByFieldId.get(key.fieldId);
    if (cellDataByRowId !== undefined) {
      cellDataByRowId.delete(key.rowId);
    }
  };

  removeWithFieldId = (fieldId: string) => {
    this.cellDataByFieldId.delete(fieldId);
  };

  insert = (key: CellCacheKey, value: any) => {
    const cellDataByRowId = this.cellDataByFieldId.get(key.fieldId);
    if (cellDataByRowId === undefined) {
      const map = new Map();
      map.set(key.rowId, value);
      this.cellDataByFieldId.set(key.fieldId, map);
    } else {
      cellDataByRowId.set(key.rowId, value);
    }
  };

  get<T>(key: CellCacheKey): Option<T> {
    const cellDataByRowId = this.cellDataByFieldId.get(key.fieldId);
    if (cellDataByRowId === undefined) {
      return None;
    } else {
      const value = cellDataByRowId.get(key.rowId);
      if (typeof value === typeof undefined) {
        return None;
      }

      // if (value satisfies T) {
      //   return Some(value as T);
      // }
      return Some(value);
    }
  }
}
