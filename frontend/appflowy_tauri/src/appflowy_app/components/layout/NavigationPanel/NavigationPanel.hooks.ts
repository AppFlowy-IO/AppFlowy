import { useAppSelector } from '$app/stores/store';
import { useNavigate } from 'react-router-dom';
import { IPage } from '$app_reducers/pages/slice';
import { ViewLayoutPB } from '@/services/backend';
import { useState } from 'react';

export const useNavigationPanelHooks = function () {
  const folders = useAppSelector((state) => state.folders);
  const pages = useAppSelector((state) => state.pages);
  const width = useAppSelector((state) => state.navigationWidth);
  const [menuHidden, setMenuHidden] = useState(false);

  const navigate = useNavigate();

  const onHideMenuClick = () => {
    setMenuHidden(true);
  };

  const onShowMenuClick = () => {
    setMenuHidden(false);
  };

  const onPageClick = (page: IPage) => {
    const pageTypeRoute = (() => {
      switch (page.pageType) {
        case ViewLayoutPB.Document:
          return 'document';
        case ViewLayoutPB.Grid:
          return 'grid';
        case ViewLayoutPB.Board:
          return 'board';
        default:
          return 'document';
      }
    })();

    navigate(`/page/${pageTypeRoute}/${page.id}`);
  };

  return {
    width,
    folders,
    pages,
    onPageClick,
    menuHidden,
    onHideMenuClick,
    onShowMenuClick,
  };
};
