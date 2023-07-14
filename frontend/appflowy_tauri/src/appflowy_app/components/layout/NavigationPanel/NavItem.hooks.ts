import { useCallback, useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { IPage, pagesActions } from '$app_reducers/pages/slice';
import { ViewLayoutPB } from '@/services/backend';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';

import { useLocation, useNavigate } from 'react-router-dom';
import { INITIAL_FOLDER_HEIGHT, PAGE_ITEM_HEIGHT } from '../../_shared/constants';

import { ViewBackendService } from '$app/stores/effects/folder/view/view_bd_svc';
import { ViewObserver } from '$app/stores/effects/folder/view/view_observer';

export enum NavItemOptions {
  More = 'More',
  NewPage = 'NewPage',
}
export const useNavItem = (page: IPage) => {
  const appDispatch = useAppDispatch();
  const workspace = useAppSelector((state) => state.workspace);
  const currentLocation = useLocation();
  const [activePageId, setActivePageId] = useState<string>('');
  const pages = useAppSelector((state) => state.pages);
  const [anchorEl, setAnchorEl] = useState<HTMLElement>();
  const menuOpen = Boolean(anchorEl);
  const [menuOption, setMenuOption] = useState<NavItemOptions>();
  const [selectedPage, setSelectedPage] = useState<IPage>();
  const onClickMenuBtn = useCallback((page: IPage, option: NavItemOptions) => {
    setSelectedPage(page);
    setMenuOption(option);
  }, []);
  const navigate = useNavigate();

  // backend
  const service = new ViewBackendService(page.id);
  const observer = new ViewObserver(page.id);

  const loadInsidePages = async () => {
    const result = await service.getChildViews();

    if (!result.ok) return;
    const views = result.val;
    const updatedPages: IPage[] = views.map<IPage>((view) => ({
      parentPageId: page.id,
      id: view.id,
      pageType: view.layout,
      title: view.name,
      showPagesInside: false,
    }));

    appDispatch(pagesActions.addInsidePages({ currentPageId: page.id, insidePages: updatedPages }));
  };

  useEffect(() => {
    void loadInsidePages();
    void observer.subscribe({
      onChildViewsChanged: () => {
        void loadInsidePages();
      },
    });
    return () => {
      // Unsubscribe when the component is unmounted.
      void observer.unsubscribe();
    };
  }, []);

  useEffect(() => {
    const { pathname } = currentLocation;
    const parts = pathname.split('/');
    const pageId = parts[parts.length - 1];

    setActivePageId(pageId);
  }, [currentLocation]);

  // recursively get all unfolded child pages
  const getChildCount: (startPage: IPage) => number = (startPage: IPage) => {
    let count = 0;

    count = pages.filter((p) => p.parentPageId === startPage.id).length;
    pages
      .filter((p) => p.parentPageId === startPage.id)
      .forEach((p) => {
        if (p.showPagesInside) {
          count += getChildCount(p);
        }
      });
    return count;
  };

  const onUnfoldClick = () => {
    appDispatch(pagesActions.toggleShowPages({ id: page.id }));
  };

  const changePageTitle = async (newTitle: string) => {
    await service.update({ name: newTitle });
    appDispatch(pagesActions.renamePage({ id: page.id, newTitle }));
    setAnchorEl(undefined);
  };

  const deletePage = async () => {
    await service.delete();
    appDispatch(pagesActions.deletePage({ id: page.id }));
    setAnchorEl(undefined);
  };

  const duplicatePage = async () => {
    await service.duplicate();
    setAnchorEl(undefined);
  };

  const onPageClick = (eventPage: IPage) => {
    const pageTypeRoute = (() => {
      switch (eventPage.pageType) {
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

    navigate(`/page/${pageTypeRoute}/${eventPage.id}`);
  };

  const onAddNewPage = async (pageType: ViewLayoutPB) => {
    if (!workspace?.id) return;

    let newPageName = '';
    let pageTypeRoute = '';

    switch (pageType) {
      case ViewLayoutPB.Document:
        newPageName = 'Document Page 1';
        pageTypeRoute = 'document';
        break;
      case ViewLayoutPB.Grid:
        newPageName = 'Grid Page 1';
        pageTypeRoute = 'grid';
        break;
      case ViewLayoutPB.Board:
        newPageName = 'Board Page 1';
        pageTypeRoute = 'board';
        break;
      default:
        newPageName = 'Document Page 1';
        pageTypeRoute = 'document';
        break;
    }

    const workspaceService = new WorkspaceBackendService(workspace.id);
    const newViewResult = await workspaceService.createView({
      name: newPageName,
      layoutType: pageType,
      parentViewId: page.id,
    });

    if (newViewResult.ok) {
      const newView = newViewResult.val;

      if (!page.showPagesInside) {
        appDispatch(pagesActions.toggleShowPages({ id: page.id }));
      }

      appDispatch(
        pagesActions.addPage({
          parentPageId: page.id,
          pageType,
          title: newView.name,
          id: newView.id,
          showPagesInside: false,
        })
      );
      setAnchorEl(undefined);
      navigate(`/page/${pageTypeRoute}/${newView.id}`);
    }
  };

  return {
    onUnfoldClick,

    changePageTitle,

    deletePage,
    duplicatePage,

    onPageClick,

    onAddNewPage,

    activePageId,
    menuOpen,
    anchorEl,
    setAnchorEl,
    menuOption,
    selectedPage,
    onClickMenuBtn,
  };
};
