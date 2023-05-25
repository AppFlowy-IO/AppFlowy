import { useAppSelector } from '@/appflowy_app/stores/store';
import { useMemo, useRef } from 'react';
import { DocumentState, Node, RangeSelectionState } from '$app/interfaces/document';
import { nodeInRange } from '$app/utils/document/blocks/common';
import { getNodeEndSelection } from '$app/utils/document/blocks/text/delta';

/**
 * Subscribe node information
 * @param id
 */
export function useSubscribeNode(id: string) {
  const node = useAppSelector<Node>((state) => state.document.nodes[id]);

  const childIds = useAppSelector<string[] | undefined>((state) => {
    const childrenId = state.document.nodes[id]?.children;
    if (!childrenId) return;
    return state.document.children[childrenId];
  });

  const isSelected = useAppSelector<boolean>((state) => {
    return state.documentRectSelection.selection.includes(id) || false;
  });

  // Memoize the node and its children
  // So that the component will not be re-rendered when other node is changed
  // It very important for performance
  const memoizedNode = useMemo(() => node, [JSON.stringify(node)]);
  const memoizedChildIds = useMemo(() => childIds, [JSON.stringify(childIds)]);

  return {
    node: memoizedNode,
    childIds: memoizedChildIds,
    isSelected,
  };
}

/**
 * Subscribe selection information
 * @param id
 */
export function useSubscribeRangeSelection(id: string) {
  const rangeRef = useRef<RangeSelectionState>();

  const currentSelection = useAppSelector((state) => {
    const range = state.documentRangeSelection;
    rangeRef.current = range;
    if (range.anchor?.id === id) {
      return range.anchor.selection;
    }
    if (range.focus?.id === id) {
      return range.focus.selection;
    }

    return getAmendInRangeNodeSelection(id, range, state.document);
  });

  return {
    rangeRef,
    currentSelection,
  };
}

function getAmendInRangeNodeSelection(id: string, range: RangeSelectionState, document: DocumentState) {
  if (!range.anchor || !range.focus || range.anchor.id === range.focus.id || range.isForward === undefined) {
    return null;
  }

  const isNodeInRange = nodeInRange(
    id,
    {
      startId: range.anchor.id,
      endId: range.focus.id,
    },
    range.isForward,
    document
  );

  if (isNodeInRange) {
    const delta = document.nodes[id].data.delta;
    return {
      anchor: {
        path: [0, 0],
        offset: 0,
      },
      focus: getNodeEndSelection(delta).anchor,
    };
  }
}
