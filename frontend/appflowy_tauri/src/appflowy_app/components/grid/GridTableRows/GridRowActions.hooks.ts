import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';

export const useGridRowActions = (controller: DatabaseController) => {
  const deleteRow = async (rowId: string) => {
    console.log('deleting row with an id', rowId);
  };

  return {
    deleteRow,
  };
};
