import { useCallback, useState } from 'react';
import { useAuth } from '../../auth/auth.hooks';

export const usePageOptions = () => {
  const [anchorEl, setAnchorEl] = useState<HTMLDivElement | HTMLButtonElement>();

  const onOptionsClick = useCallback((el: HTMLDivElement | HTMLButtonElement) => {
    setAnchorEl(el);
  }, []);

  const onClose = () => {
    setAnchorEl(undefined);
  };

  return {
    anchorEl,
    onOptionsClick,
    onClose,
  };
};
