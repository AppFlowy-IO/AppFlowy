import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { useNavigate } from 'react-router-dom';
import { IPage } from '../../../stores/reducers/pages/slice';
import { ViewLayoutTypePB } from '../../../../services/backend';
import { MouseEventHandler, useState } from 'react';
import { activePageIdActions } from '../../../stores/reducers/activePageId/slice';

// number of pixels from left side of screen to show hidden navigation panel
const FLOATING_PANEL_SHOW_WIDTH = 10;
const FLOATING_PANEL_HIDE_EXTRA_WIDTH = 10;

export const useNavigationPanelHooks = function () {
  const dispatch = useAppDispatch();
  const folders = useAppSelector((state) => state.folders);
  const pages = useAppSelector((state) => state.pages);
  const width = useAppSelector((state) => state.navigationWidth);
  const [navigationPanelFixed, setNavigationPanelFixed] = useState(true);
  const [slideInFloatingPanel, setSlideInFloatingPanel] = useState(true);
  const [menuHidden, setMenuHidden] = useState(false);

  const navigate = useNavigate();

  const onCollapseNavigationClick = () => {
    setSlideInFloatingPanel(true);
    setNavigationPanelFixed(false);
  };

  const onFixNavigationClick = () => {
    setNavigationPanelFixed(true);
  };

  const [floatingPanelWidth, setFloatingPanelWidth] = useState(0);

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

    dispatch(activePageIdActions.setActivePageId(page.id));

    navigate(`/page/${pageTypeRoute}/${page.id}`);
  };

  const onScreenMouseMove: MouseEventHandler<HTMLDivElement> = (e) => {
    if (e.screenX <= FLOATING_PANEL_SHOW_WIDTH) {
      setSlideInFloatingPanel(true);
    } else if (e.screenX > floatingPanelWidth + FLOATING_PANEL_HIDE_EXTRA_WIDTH) {
      setSlideInFloatingPanel(false);
    }
  };

  return {
    width,

    folders,
    pages,

    navigate,
    onPageClick,

    onCollapseNavigationClick,
    onFixNavigationClick,
    navigationPanelFixed,
    onScreenMouseMove,
    slideInFloatingPanel,
    setFloatingPanelWidth,
    menuHidden,
    onHideMenuClick,
    onShowMenuClick,
  };
};
