import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
import { useCallback } from 'react';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppDispatch } from '$app/stores/store';

export function useDocumentTitle(id: string) {
  const { node } = useSubscribeNode(id);
  const { controller } = useSubscribeDocument();
  const dispatch = useAppDispatch();
  const onUpdateIcon = useCallback(
    (icon: string) => {
      dispatch(
        updateNodeDataThunk({
          id,
          data: {
            icon,
          },
          controller,
        })
      );
    },
    [controller, dispatch, id]
  );

  const onUpdateCover = useCallback(
    (coverType: 'image' | 'color' | '', cover: string) => {
      dispatch(
        updateNodeDataThunk({
          id,
          data: {
            cover,
            coverType,
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
