import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { useState } from 'react';

export const useGridTableRow = (controller: DatabaseController) => {
  const [showMenu, setShowMenu] = useState(false);

  const addRowAt = async (index: number) => {
    console.log('addRowAt', index);
    const row = await controller.createRow();
  };

  return {
    showMenu,
    setShowMenu,
    addRowAt,
  };
};
