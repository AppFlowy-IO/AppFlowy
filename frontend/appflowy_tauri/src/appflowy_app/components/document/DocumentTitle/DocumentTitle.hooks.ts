import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
import { useCallback, useEffect } from 'react';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { ViewIconTypePB } from '@/services/backend';
import { updatePageIcon } from '$app_reducers/pages/async_actions';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { CoverType } from '$app/interfaces/document';
import { documentActions } from "$app_reducers/document/slice";

export function useDocumentTitle(id: string) {
  const { node } = useSubscribeNode(id);
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();
  const page = useAppSelector((state) => state.pages.pageMap[docId]);

  useEffect(() => {
    if (page) {
      dispatch(
        documentActions.updateRootNodeDelta({
          docId,
          delta: [{ insert: page.name }],
          rootId: id,
        })
      );
    }
  }, [dispatch, docId, id, page]);

  const onUpdateIcon = useCallback(
    (icon: string) => {
      dispatch(
        updatePageIcon({
          id: docId,
          icon: icon
            ? {
                ty: ViewIconTypePB.Emoji,
                value: icon,
              }
            : undefined,
        })
      );
    },
    [dispatch, docId]
  );

  const onUpdateCover = useCallback(
    (coverType: CoverType | null, cover: string | null) => {
      dispatch(
        updateNodeDataThunk({
          id,
          data: {
            coverType: coverType || '',
            cover: cover || '',
          },
          controller,
        })
      );
    },
    [controller, dispatch, id]
  );

  return {
    node,
    onUpdateCover,
    onUpdateIcon,
  };
}
