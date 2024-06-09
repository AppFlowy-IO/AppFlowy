import { useCallback, useEffect } from 'react';
import { pagesActions, parserViewPBToPage } from '$app_reducers/pages/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { FolderNotification, ViewLayoutPB } from '@/services/backend';
import { useParams } from 'react-router-dom';
import { openPage, updatePageName } from '$app_reducers/pages/async_actions';
import { createPage, deletePage, duplicatePage, getChildPages } from '$app/application/folder/page.service';
import { subscribeNotifications } from '$app/application/notification';

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
        [FolderNotification.DidUpdateView]: async (payload) => {
          const childViews = payload.child_views;

          if (childViews.length === 0) {
            return;
          }

          dispatch(
            pagesActions.addChildPages({
              id: pageId,
              childPages: childViews.map(parserViewPBToPage),
            })
          );
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
  }, [pageId, loadPageChildren, dispatch]);

  return {
    toggleCollapsed,
    collapsed,
    childPages,
  };
}

export function usePageActions(pageId: string) {
  const page = useAppSelector((state) => state.pages.pageMap[pageId]);
  const dispatch = useAppDispatch();
  const params = useParams();
  const currentPageId = params.id;

  const onPageClick = useCallback(() => {
    void dispatch(openPage(pageId));
  }, [dispatch, pageId]);

  const onAddPage = useCallback(
    async (layout: ViewLayoutPB) => {
      const newViewId = await createPage({
        layout,
        name: '',
        parent_view_id: pageId,
      });

      dispatch(
        pagesActions.addPage({
          page: {
            id: newViewId,
            parentId: pageId,
            layout,
            name: '',
          },
          isLast: true,
        })
      );

      dispatch(pagesActions.expandPage(pageId));
      await dispatch(openPage(newViewId));
    },
    [dispatch, pageId]
  );

  const onDeletePage = useCallback(async () => {
    if (currentPageId === pageId) {
      dispatch(pagesActions.setTrashSnackbar(true));
    }

    await deletePage(pageId);
    dispatch(pagesActions.deletePages([pageId]));
  }, [dispatch, pageId, currentPageId]);

  const onDuplicatePage = useCallback(async () => {
    await duplicatePage(page);
  }, [page]);

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
  return useParams().id === pageId;
}
