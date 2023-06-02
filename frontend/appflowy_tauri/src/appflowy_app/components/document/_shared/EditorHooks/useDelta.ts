import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useCallback, useContext, useEffect, useMemo, useRef } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '$app/stores/store';
import { updateNodeDeltaThunk } from '$app_reducers/document/async-actions';
import Delta from 'quill-delta';

export function useDelta({ id, onDeltaChange }: { id: string; onDeltaChange?: (delta: Delta) => void }) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const penddingRef = useRef(false);
  const { node } = useSubscribeNode(id);

  const delta = useMemo(() => {
    if (!node || !node.data.delta) return new Delta();
    return new Delta(node.data.delta);
  }, [node]);

  useEffect(() => {
    onDeltaChange?.(delta);
  }, [delta, onDeltaChange]);

  const update = useCallback(
    async (delta: Delta) => {
      if (!controller) return;
      await dispatch(
        updateNodeDeltaThunk({
          id,
          delta: delta.ops,
          controller,
        })
      );
      // reset pendding flag
      penddingRef.current = false;
    },
    [controller, dispatch, id]
  );

  return {
    update,
    delta,
  };
}
