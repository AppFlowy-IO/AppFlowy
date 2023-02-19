/* eslint-disable @typescript-eslint/no-explicit-any */
export class CellCacheKey {
  constructor(public readonly fieldId: string, public readonly rowId: string) {}
}

export class CellCache {
  _cellDataByFieldId = new Map<string, Map<string, any>>();

  constructor(public readonly databaseId: string) {}

  remove = (key: CellCacheKey) => {
    const inner = this._cellDataByFieldId.get(key.fieldId);
    if (inner !== undefined) {
      inner.delete(key.rowId);
    }
  };

  removeWithFieldId = (fieldId: string) => {
    this._cellDataByFieldId.delete(fieldId);
  };

  insert = (key: CellCacheKey, value: any) => {
    let inner = this._cellDataByFieldId.get(key.fieldId);
    if (inner === undefined) {
      inner = this._cellDataByFieldId.set(key.fieldId, new Map());
    }
    inner.set(key.rowId, value);
  };

  get<T>(key: CellCacheKey): T | null {
    const inner = this._cellDataByFieldId.get(key.fieldId);
    if (inner === undefined) {
      return null;
    } else {
      const value = inner.get(key.rowId);
      if (typeof value === typeof undefined || typeof value === typeof null) {
        return null;
      }
      if (value satisfies T) {
        return value as T;
      }
      return null;
    }
  }
}
