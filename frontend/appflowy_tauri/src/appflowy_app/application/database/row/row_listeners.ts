import { ReorderAllRowsPB, ReorderSingleRowPB, RowsChangePB, RowsVisibilityChangePB } from '@/services/backend';
import { Database } from '../database';
import { pbToRowMeta, RowMeta } from './row_types';
import { didDeleteCells } from '$app/application/database/cell/cell_listeners';
import { getDatabase } from '$app/application/database/database/database_service';

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

const updateRowsFromChangeset = (database: Database, changeset: RowsChangePB) => {
  changeset.updated_rows.forEach(({ row_id: rowId, row_meta: rowMetaPB }) => {
    const found = database.rowMetas.find((rowMeta) => rowMeta.id === rowId);

    if (found) {
      Object.assign(found, rowMetaPB ? pbToRowMeta(rowMetaPB) : {});
    }
  });
};

export const didUpdateViewRows = async (viewId: string, database: Database, changeset: RowsChangePB) => {
  if (changeset.inserted_rows.length > 0) {
    const { rowMetas } = await getDatabase(viewId);

    database.rowMetas = rowMetas;
    return;
  }

  deleteRowsFromChangeset(database, changeset);
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

export const didUpdateViewRowsVisibility = async (
  viewId: string,
  database: Database,
  changeset: RowsVisibilityChangePB
) => {
  const { invisible_rows, visible_rows } = changeset;

  let reFetchRows = false;

  for (const rowId of invisible_rows) {
    const rowMeta = database.rowMetas.find((rowMeta) => rowMeta.id === rowId);

    if (rowMeta) {
      rowMeta.isHidden = true;
    }
  }

  for (const insertedRow of visible_rows) {
    const rowMeta = database.rowMetas.find((rowMeta) => rowMeta.id === insertedRow.row_meta.id);

    if (rowMeta) {
      rowMeta.isHidden = false;
    } else {
      reFetchRows = true;
      break;
    }
  }

  if (reFetchRows) {
    const { rowMetas } = await getDatabase(viewId);

    database.rowMetas = rowMetas;

    await didUpdateViewRowsVisibility(viewId, database, changeset);
  }
};
