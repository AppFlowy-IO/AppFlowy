import { useCallback, useEffect, useMemo } from 'react';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { Page, pagesActions, pageTypeMap } from '$app_reducers/pages/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { ViewLayoutPB } from '@/services/backend';
import { useNavigate, useParams } from 'react-router-dom';
import { updatePageName } from '$app_reducers/pages/async_actions';

export function useLoadChildPages(pageId: string) {
  const dispatch = useAppDispatch();
  const childPages = useAppSelector((state) => state.pages.relationMap[pageId]);
  const collapsed = useAppSelector((state) => !state.pages.expandedIdMap[pageId]);
  const toggleCollapsed = useCallback(() => {
    if (collapsed) {
      dispatch(pagesActions.expandPage(pageId));
    } else {
      dispatch(pagesActions.collapsePage(pageId));
    }
  }, [dispatch, pageId, collapsed]);

  const controller = useMemo(() => {
    return new PageController(pageId);
  }, [pageId]);

  const onPageChanged = useCallback(
    (page: Page, children: Page[]) => {
      dispatch(pagesActions.onPageChanged(page));
      dispatch(
        pagesActions.addChildPages({
          id: page.id,
          childPages: children,
        })
      );
    },
    [dispatch]
  );

  const loadPageChildren = useCallback(
    async (pageId: string) => {
      const childPages = await controller.getChildPages();

      dispatch(
        pagesActions.addChildPages({
          id: pageId,
          childPages,
        })
      );
    },
    [controller, dispatch]
  );

  useEffect(() => {
    void loadPageChildren(pageId);
  }, [loadPageChildren, pageId]);

  useEffect(() => {
    void controller.subscribe({
      onPageChanged,
    });
    return () => {
      void controller.dispose();
    };
  }, [controller, onPageChanged]);

  return {
    toggleCollapsed,
    collapsed,
    childPages,
  };
}

export function usePageActions(pageId: string) {
  const page = useAppSelector((state) => state.pages.pageMap[pageId]);
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const controller = useMemo(() => {
    return new PageController(pageId);
  }, [pageId]);

  const onPageClick = useCallback(() => {
    const pageType = pageTypeMap[page.layout];

    navigate(`/page/${pageType}/${pageId}`);
  }, [navigate, page.layout, pageId]);

  const onAddPage = useCallback(
    async (layout: ViewLayoutPB) => {
      const newViewId = await controller.createPage({
        layout,
        name: '',
      });

      dispatch(pagesActions.expandPage(pageId));
      const pageType = pageTypeMap[layout];

      navigate(`/page/${pageType}/${newViewId}`);
    },
    [controller, dispatch, navigate, pageId]
  );

  const onDeletePage = useCallback(async () => {
    await controller.deletePage();
  }, [controller]);

  const onDuplicatePage = useCallback(async () => {
    await controller.duplicatePage();
  }, [controller]);

  const onRenamePage = useCallback(
    async (name: string) => {
      await dispatch(updatePageName({ id: pageId, name }));
    },
    [dispatch, pageId]
  );

  useEffect(() => {
    return () => {
      void controller.dispose();
    };
  }, [controller]);

  return {
    onAddPage,
    onPageClick,
    onRenamePage,
    onDeletePage,
    onDuplicatePage,
  };
}

export function useSelectedPage(pageId: string) {
  const id = useParams().id;

  return id === pageId;
}
