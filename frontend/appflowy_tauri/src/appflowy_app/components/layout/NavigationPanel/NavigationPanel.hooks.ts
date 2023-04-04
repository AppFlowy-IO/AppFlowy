import { useAppSelector } from '../../../stores/store';
import { useNavigate } from 'react-router-dom';
import { IPage } from '../../../stores/reducers/pages/slice';
import { ViewLayoutTypePB } from '@/services/backend';
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
    let pageTypeRoute = (() => {
      switch (page.pageType) {
        case ViewLayoutTypePB.Document:
          return 'document';
          break;
        case ViewLayoutTypePB.Grid:
          return 'grid';
        case ViewLayoutTypePB.Board:
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
