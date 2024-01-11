import { Database } from '$app/application/database';
import { getCell } from './cell_service';

export function didDeleteCells({ database, rowId, fieldId }: { database: Database; rowId?: string; fieldId?: string }) {
  const ids = Object.keys(database.cells);

  ids.forEach((id) => {
    const cell = database.cells[id];

    if (rowId && cell.rowId !== rowId) return;
    if (fieldId && cell.fieldId !== fieldId) return;

    delete database.cells[id];
  });
}

export async function didUpdateCells({
  viewId,
  database,
  rowId,
  fieldId,
}: {
  viewId: string;
  database: Database;
  rowId?: string;
  fieldId?: string;
}) {
  const field = database.fields.find((field) => field.id === fieldId);

  if (!field) {
    delete database.cells[`${rowId}:${fieldId}`];
    return;
  }

  const ids = Object.keys(database.cells);

  ids.forEach((id) => {
    const cell = database.cells[id];

    if (rowId && cell.rowId !== rowId) return;
    if (fieldId && cell.fieldId !== fieldId) return;

    void getCell(viewId, cell.rowId, cell.fieldId, field.type).then((data) => {
      // cache cell
      database.cells[id] = data;
    });
  });
}
