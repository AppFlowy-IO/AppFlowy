import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { useState } from 'react';

export const useGridTableRow = (controller: DatabaseController) => {
  const [showMenu, setShowMenu] = useState(false);

  const addRowAt = async (id: string) => {
    await controller.createRowAfter(id);
  };

  return {
    showMenu,
    setShowMenu,
    addRowAt,
  };
};
