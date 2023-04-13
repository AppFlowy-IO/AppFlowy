import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';

export const useGridAddRow = (controller: DatabaseController) => {
  async function addRow() {
    await controller.createRow();
  }

  return {
    addRow,
  };
};
