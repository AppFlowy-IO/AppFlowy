import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';


export const useGridRowActions = (controller: DatabaseController) => {
  const deleteRow = async (rowId: string) => {
    console.log('deleting row with an id', rowId);
  };


  const insertRowAfter = async (rowId: string) => {
    console.log('inserting row after', rowId);
  };

  const duplicateRow = async (rowId: string) => {
    console.log('duplicating row with an id', rowId);
  };

  return {
    deleteRow,
    insertRowAfter,  
    duplicateRow
  };
};
