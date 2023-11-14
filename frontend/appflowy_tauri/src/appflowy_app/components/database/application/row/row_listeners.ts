import {
  ReorderAllRowsPB,
  ReorderSingleRowPB,
  RowsChangePB,
} from '@/services/backend';
import { Database } from '../database';
import { pbToRowMeta, RowMeta } from './row_types';

const deleteRowsFromChangeset = (database: Database, changeset: RowsChangePB) => {
  changeset.deleted_rows.forEach(rowId => {
    const index = database.rowMetas.findIndex(row => row.id === rowId);

    if (index !== -1) {
      database.rowMetas.splice(index, 1);
    }
  });
};

const insertRowsFromChangeset = (database: Database, changeset: RowsChangePB) => {
  changeset.inserted_rows.forEach(({ index, row_meta: rowMetaPB }) => {
    database.rowMetas.splice(index, 0, pbToRowMeta(rowMetaPB));
  });
};

const updateRowsFromChangeset = (database: Database, changeset: RowsChangePB) => {
  changeset.updated_rows.forEach(({ row_id: rowId, row_meta: rowMetaPB }) => {
    const found = database.rowMetas.find(rowMeta => rowMeta.id === rowId);

    if (found) {
      Object.assign(found, pbToRowMeta(rowMetaPB));
    }
  });
};

export const didUpdateViewRows = (database: Database, changeset: RowsChangePB) => {
  deleteRowsFromChangeset(database, changeset);
  insertRowsFromChangeset(database, changeset);
  updateRowsFromChangeset(database, changeset);
};

export const didReorderRows = (database: Database, changeset: ReorderAllRowsPB) => {
  const rowById = database.rowMetas.reduce<Record<string, RowMeta>>((prev, cur) => {
    prev[cur.id] = cur;
    return prev;
  }, {});

  database.rowMetas = changeset.row_orders.map(rowId => rowById[rowId]);
};

export const didReorderSingleRow = (database: Database, changeset: ReorderSingleRowPB) => {
  const {
    row_id: rowId,
    new_index: newIndex,
  } = changeset;

  const oldIndex = database.rowMetas.findIndex(rowMeta => rowMeta.id === rowId);

  if (oldIndex !== -1) {
    database.rowMetas.splice(newIndex, 0, database.rowMetas.splice(oldIndex, 1)[0]);
  }
};
