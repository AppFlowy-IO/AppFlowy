import { useState } from 'react';

export const useGridTableRow = () => {
  const [showMenu, setShowMenu] = useState(false);

  return {
    showMenu,
    setShowMenu,
  };
};
