import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useCallback, useContext, useEffect, useMemo, useRef } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { updateNodeDeltaThunk } from '$app_reducers/document/async-actions';
import Delta, { Op } from 'quill-delta';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useDelta({ id, onDeltaChange }: { id: string; onDeltaChange?: (delta: Delta) => void }) {
  const { controller } = useSubscribeDocument();
  const dispatch = useAppDispatch();
  const penddingRef = useRef(false);
  const { delta: deltaStr } = useSubscribeNode(id);

  const delta = useMemo(() => {
    if (!deltaStr) return new Delta();
    const deltaJson = JSON.parse(deltaStr);

    return new Delta(deltaJson);
  }, [deltaStr]);

  useEffect(() => {
    onDeltaChange?.(delta);
  }, [delta, onDeltaChange]);

  const update = useCallback(
    async (ops: Op[], newDelta: Delta) => {
      if (!controller) return;
      await dispatch(
        updateNodeDeltaThunk({
          id,
          ops,
          newDelta,
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
