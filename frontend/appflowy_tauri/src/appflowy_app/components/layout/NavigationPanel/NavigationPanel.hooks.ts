import { useAppSelector } from '$app/stores/store';
import { useState } from 'react';

export const useNavigationPanelHooks = function () {
  const width = useAppSelector((state) => state.navigationWidth);
  const [menuHidden, setMenuHidden] = useState(false);

  const onHideMenuClick = () => {
    setMenuHidden(true);
  };

  const onShowMenuClick = () => {
    setMenuHidden(false);
  };

  return {
    width,
    menuHidden,
    onHideMenuClick,
    onShowMenuClick,
  };
};
