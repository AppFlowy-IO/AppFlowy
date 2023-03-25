import { useEffect } from 'react';
import { DocumentData, NestedBlock } from '$app/interfaces/document';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { documentActions, Node } from '$app/stores/reducers/document/slice';

export function useParseTree(documentData: DocumentData) {
  const dispatch = useAppDispatch();
  const { blocks, ytexts, yarrays, rootId } = documentData;
  const flattenNestedBlocks = (
    block: NestedBlock
  ): (Node & {
    children: string[];
  })[] => {
    const node: Node & {
      children: string[];
    } = {
      id: block.id,
      delta: ytexts[block.data.text],
      data: block.data,
      type: block.type,
      parent: block.parent,
      children: yarrays[block.children],
    };

    const nodes = [node];
    node.children.forEach((child) => {
      const childBlock = blocks[child];
      nodes.push(...flattenNestedBlocks(childBlock));
    });
    return nodes;
  };

  const initializeNodeHierarchy = (parentId: string, children: string[]) => {
    children.forEach((childId) => {
      dispatch(documentActions.addChild({ parentId, childId }));
      const child = blocks[childId];
      initializeNodeHierarchy(childId, yarrays[child.children]);
    });
  };

  useEffect(() => {
    const root = documentData.blocks[rootId];

    const initialNodes = flattenNestedBlocks(root);

    initialNodes.forEach((node) => {
      const _node = {
        id: node.id,
        parent: node.parent,
        data: node.data,
        type: node.type,
        delta: node.delta,
      };
      dispatch(documentActions.addNode(_node));
    });

    initializeNodeHierarchy(rootId, yarrays[root.children]);

    return () => {
      dispatch(documentActions.clear());
    };
  }, [documentData]);
}
