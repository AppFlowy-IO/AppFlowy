import { useCallback, useEffect, useMemo } from 'react';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { Page, pagesActions } from '$app_reducers/pages/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { ViewLayoutPB } from '@/services/backend';
import { useNavigate, useParams } from 'react-router-dom';
import { pageTypeMap } from '$app/constants';
import { useTranslation } from 'react-i18next';

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

  const onChildPagesChanged = useCallback(
    (childPages: Page[]) => {
      dispatch(
        pagesActions.addChildPages({
          id: pageId,
          childPages,
        })
      );
    },
    [dispatch, pageId]
  );

  const onPageChanged = useCallback(
    (page: Page) => {
      dispatch(pagesActions.onPageChanged(page));
    },
    [dispatch]
  );

  const onPageCollapsed = useCallback(async () => {
    dispatch(pagesActions.removeChildPages(pageId));
    await controller.unsubscribe();
  }, [dispatch, pageId, controller]);

  const onPageExpanded = useCallback(async () => {
    const childPages = await controller.getChildPages();

    dispatch(
      pagesActions.addChildPages({
        id: pageId,
        childPages,
      })
    );
    await controller.subscribe({
      onChildPagesChanged,
      onPageChanged,
    });
  }, [controller, dispatch, onChildPagesChanged, onPageChanged, pageId]);

  useEffect(() => {
    if (collapsed) {
      onPageCollapsed();
    } else {
      onPageExpanded();
    }
  }, [collapsed, onPageCollapsed, onPageExpanded]);

  useEffect(() => {
    return () => {
      controller.dispose();
    };
  }, [controller]);

  return {
    toggleCollapsed,
    collapsed,
    childPages,
  };
}

export function usePageActions(pageId: string) {
  const page = useAppSelector((state) => state.pages.pageMap[pageId]);
  const { t } = useTranslation();
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
        name: t('document.title.placeholder'),
      });

      dispatch(pagesActions.expandPage(pageId));
      const pageType = pageTypeMap[layout];

      navigate(`/page/${pageType}/${newViewId}`);
    },
    [t, controller, dispatch, navigate, pageId]
  );

  const onDeletePage = useCallback(async () => {
    await controller.deletePage();
  }, [controller]);

  const onDuplicatePage = useCallback(async () => {
    await controller.duplicatePage();
  }, [controller]);

  const onRenamePage = useCallback(
    async (name: string) => {
      await controller.updatePage({
        id: pageId,
        name,
      });
    },
    [controller, pageId]
  );

  useEffect(() => {
    return () => {
      controller.dispose();
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
