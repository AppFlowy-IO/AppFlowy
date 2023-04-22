import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { documentActions } from '@/appflowy_app/stores/reducers/document/slice';
import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { useCallback, useContext, useRef, useState, useEffect } from 'react';
import { insertAfterNodeThunk, deleteNodeThunk } from '@/appflowy_app/stores/reducers/document/async_actions';

export function useBlockMenu(nodeId: string, open: boolean) {
  const ref = useRef<HTMLDivElement | null>(null);
  const { insertAfter, remove } = useActions(nodeId);
  const dispatch = useAppDispatch();
  const [style, setStyle] = useState({ top: '0px', left: '0px' });

  useEffect(() => {
    if (!open) {
      return;
    }
    // set selection when open
    dispatch(documentActions.setSelectionById(nodeId));
    // get node rect
    const rect = document.querySelector(`[data-block-id="${nodeId}"]`)?.getBoundingClientRect();
    if (!rect) return;
    // set menu position
    setStyle({
      top: rect.top + 'px',
      left: rect.left + 'px',
    });
  }, [open, nodeId]);

  const handleAddClick = useCallback(async () => {
    if (!nodeId) return;
    await insertAfter();
  }, [nodeId, insertAfter]);

  const handleDeleteClick = useCallback(async () => {
    if (!nodeId) return;
    await remove();
  }, [remove, nodeId]);

  return {
    ref,
    style,
    handleAddClick,
    handleDeleteClick,
  };
}

function useActions(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const { node } = useSubscribeNode(id);

  const insertAfter = useCallback(async () => {
    if (!controller || !node) return;
    await dispatch(insertAfterNodeThunk({ id: node.id, controller }));
  }, [node, controller, dispatch]);

  const remove = useCallback(async () => {
    if (!controller || !node) return;
    await dispatch(deleteNodeThunk({ id: node.id, controller }));
  }, [node, dispatch]);

  return {
    insertAfter,
    remove,
  };
}
