import { useCallback, useEffect, useMemo } from 'react';
import { Page, pagesActions, pageTypeMap } from '$app_reducers/pages/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { FolderNotification, ViewLayoutPB } from '@/services/backend';
import { useNavigate, useParams } from 'react-router-dom';
import { updatePageName } from '$app_reducers/pages/async_actions';
import { createPage, deletePage, duplicatePage, getChildPages } from '$app/application/folder/page.service';
import { subscribeNotifications } from '$app/application/notification';
import debounce from 'lodash-es/debounce';

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

  const onPageChanged = useMemo(() => {
    return debounce((page: Page) => {
      console.log('DidUpdateView');

      dispatch(pagesActions.onPageChanged(page));
    }, 200);
  }, [dispatch]);

  const loadPageChildren = useCallback(
    async (pageId: string) => {
      const childPages = await getChildPages(pageId);

      dispatch(
        pagesActions.addChildPages({
          id: pageId,
          childPages,
        })
      );
    },
    [dispatch]
  );

  useEffect(() => {
    void loadPageChildren(pageId);
  }, [loadPageChildren, pageId]);

  useEffect(() => {
    const unsubscribePromise = subscribeNotifications(
      {
        [FolderNotification.DidUpdateView]: (_payload) => {
          // const page = parserViewPBToPage(payload);
          // onPageChanged(page);
        },
        [FolderNotification.DidUpdateChildViews]: async (payload) => {
          if (payload.delete_child_views.length === 0 && payload.create_child_views.length === 0) {
            return;
          }

          void loadPageChildren(pageId);
        },
      },
      {
        id: pageId,
      }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [pageId, onPageChanged, loadPageChildren]);

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

  const onPageClick = useCallback(() => {
    const pageType = pageTypeMap[page.layout];

    navigate(`/page/${pageType}/${pageId}`);
  }, [navigate, page.layout, pageId]);

  const onAddPage = useCallback(
    async (layout: ViewLayoutPB) => {
      const newViewId = await createPage({
        layout,
        name: '',
        parent_view_id: pageId,
      });

      dispatch(pagesActions.expandPage(pageId));
      const pageType = pageTypeMap[layout];

      navigate(`/page/${pageType}/${newViewId}`);
    },
    [dispatch, navigate, pageId]
  );

  const onDeletePage = useCallback(async () => {
    await deletePage(pageId);
  }, [pageId]);

  const onDuplicatePage = useCallback(async () => {
    await duplicatePage(pageId);
  }, [pageId]);

  const onRenamePage = useCallback(
    async (name: string) => {
      await dispatch(updatePageName({ id: pageId, name }));
    },
    [dispatch, pageId]
  );

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
