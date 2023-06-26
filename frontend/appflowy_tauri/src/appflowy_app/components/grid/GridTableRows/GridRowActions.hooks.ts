import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';

export const useGridRowActions = (controller: DatabaseController) => {
  const deleteRow = async (rowId: string) => {
    await controller.deleteRow(rowId);
  };

  const insertRowAfter = async (rowId: string) => {
    console.log('inserting row after', rowId);
    // TODO: insert row after
    // await controller.insertRowAfter(rowId);
  };

  const duplicateRow = async (rowId: string) => {
    await controller.duplicateRow(rowId);
  };

  return {
    deleteRow,
    insertRowAfter,
    duplicateRow,
  };
};
