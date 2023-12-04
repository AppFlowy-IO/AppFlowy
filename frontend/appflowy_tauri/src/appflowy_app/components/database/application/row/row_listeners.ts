import { ReorderAllRowsPB, ReorderSingleRowPB, RowsChangePB, RowsVisibilityChangePB } from '@/services/backend';
import { Database } from '../database';
import { pbToRowMeta, RowMeta } from './row_types';
import { didDeleteCells } from '$app/components/database/application/cell/cell_listeners';

const deleteRowsFromChangeset = (database: Database, changeset: RowsChangePB) => {
  changeset.deleted_rows.forEach((rowId) => {
    const index = database.rowMetas.findIndex((row) => row.id === rowId);

    if (index !== -1) {
      database.rowMetas.splice(index, 1);
      // delete cells
      didDeleteCells({ database, rowId });
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
    const found = database.rowMetas.find((rowMeta) => rowMeta.id === rowId);

    if (found) {
      Object.assign(found, rowMetaPB ? pbToRowMeta(rowMetaPB) : {});
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

  database.rowMetas = changeset.row_orders.map((rowId) => rowById[rowId]);
};

export const didReorderSingleRow = (database: Database, changeset: ReorderSingleRowPB) => {
  const { row_id: rowId, new_index: newIndex } = changeset;

  const oldIndex = database.rowMetas.findIndex((rowMeta) => rowMeta.id === rowId);

  if (oldIndex !== -1) {
    database.rowMetas.splice(newIndex, 0, database.rowMetas.splice(oldIndex, 1)[0]);
  }
};

export const didUpdateViewRowsVisibility = (database: Database, changeset: RowsVisibilityChangePB) => {
  const { invisible_rows, visible_rows } = changeset;

  database.rowMetas.forEach((rowMeta) => {
    if (invisible_rows.includes(rowMeta.id)) {
      rowMeta.isHidden = true;
    }

    const found = visible_rows.find((visibleRow) => visibleRow.row_meta.id === rowMeta.id);

    if (found) {
      rowMeta.isHidden = false;
    }
  });
};
