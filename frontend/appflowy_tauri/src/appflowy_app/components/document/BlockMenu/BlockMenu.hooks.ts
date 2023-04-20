import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { documentActions, Node } from '@/appflowy_app/stores/reducers/document/slice';
import { nanoid } from 'nanoid';
import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { useCallback, useContext, useRef, useState, useEffect } from 'react';
import { BlockType } from '@/appflowy_app/interfaces/document';
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
  }, [open]);

  const handleAddClick = useCallback(async () => {
    if (!nodeId) return;
    await insertAfter();
  }, [nodeId, insertAfter]);

  const handleDeleteClick = useCallback(async () => {
    if (!nodeId) return;
    await remove();
  }, []);

  return {
    ref,
    style,
    handleAddClick,
    handleDeleteClick,
  };
}

function useController() {
  const controller = useContext(DocumentControllerContext);

  const insertAfter = useCallback(async (node: Node, parentId: string, prevId: string) => {
    if (!controller) return;
    await controller.applyActions([controller.getInsertAction(node, prevId)]);
  }, []);

  const remove = useCallback(async (node: Node) => {
    if (!controller) return;
    await controller.applyActions([controller.getDeleteAction(node)]);
  }, []);

  return {
    insertAfter,
    remove,
  };
}

function useActions(id: string) {
  const dispatch = useAppDispatch();
  const { insertAfter: collabInsertAfter, remove: collabRemove } = useController();

  const { node } = useSubscribeNode(id);

  const insertAfter = useCallback(async () => {
    if (!node) return;
    const parentId = node.parent;
    if (!parentId) return;
    // create new node
    const newNode: Node = {
      id: nanoid(10),
      parent: parentId,
      type: BlockType.TextBlock,
      data: {},
      children: nanoid(10),
    };
    // insert new node
    await collabInsertAfter(newNode, parentId, node.id);
    // update UI state
    dispatch(documentActions.setBlockMap(newNode));
    dispatch(documentActions.insertChild({ id: parentId, prevId: node.id, childId: newNode.id }));
  }, [node, dispatch, collabInsertAfter]);

  const remove = useCallback(async () => {
    if (!node || !node.parent) return;
    // remove node
    await collabRemove(node);
    // update UI state
    dispatch(documentActions.removeBlockMapKey(node.id));
    dispatch(documentActions.deleteChild({ id: node.parent, childId: node.id }));
  }, [node, dispatch, collabRemove]);

  return {
    insertAfter,
    remove,
  };
}
