import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
import { useEffect } from 'react';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { documentActions } from '$app_reducers/document/slice';

export function useDocumentTitle(id: string) {
  const { node } = useSubscribeNode(id);
  const dispatch = useAppDispatch();
  const { docId } = useSubscribeDocument();
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

  return {
    node,
  };
}
