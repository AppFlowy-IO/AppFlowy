import { useCallback, useEffect, useRef, useState } from 'react';
import { BlockEditor } from '@/appflowy_app/block_editor';
import { TreeNode } from '$app/block_editor/view/tree_node';
import { Alert } from '@mui/material';
import { FallbackProps } from 'react-error-boundary';
import { TextBlockManager } from '@/appflowy_app/block_editor/blocks/text_block';
import { TextBlockContext } from '@/appflowy_app/utils/slate/context';
import { useVirtualizer } from '@tanstack/react-virtual';
export interface BlockListProps {
  blockId: string;
  blockEditor: BlockEditor;
}

const defaultSize = 45;

export function useBlockList({ blockId, blockEditor }: BlockListProps) {
  const [root, setRoot] = useState<TreeNode | null>(null);

  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: root?.children.length || 0,
    getScrollElement: () => parentRef.current,
    overscan: 5,
    estimateSize: () => {
      return defaultSize;
    },
  });

  const [version, forceUpdate] = useState<number>(0);

  const buildDeepTree = useCallback(() => {
    const treeNode = blockEditor.renderTree.buildDeep(blockId);
    setRoot(treeNode);
  }, [blockEditor]);

  useEffect(() => {
    if (!parentRef.current) return;
    blockEditor.renderTree.createPositionManager(parentRef.current);
    buildDeepTree();

    return () => {
      blockEditor.destroy();
    };
  }, [blockId, blockEditor]);

  useEffect(() => {
    root?.registerUpdate(() => forceUpdate((prev) => prev + 1));
    return () => {
      root?.unregisterUpdate();
    };
  }, [root]);

  return {
    root,
    rowVirtualizer,
    parentRef,
    blockEditor,
  };
}

export function ErrorBoundaryFallbackComponent({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <Alert severity='error' className='mb-2'>
      <p>Something went wrong:</p>
      <pre>{error.message}</pre>
      <button onClick={resetErrorBoundary}>Try again</button>
    </Alert>
  );
}

export function withTextBlockManager(Component: (props: BlockListProps) => React.ReactElement) {
  return (props: BlockListProps) => {
    const textBlockManager = new TextBlockManager(props.blockEditor.operation);

    useEffect(() => {
      return () => {
        textBlockManager.destroy();
      };
    }, []);

    return (
      <TextBlockContext.Provider
        value={{
          textBlockManager,
        }}
      >
        <Component {...props} />
      </TextBlockContext.Provider>
    );
  };
}
