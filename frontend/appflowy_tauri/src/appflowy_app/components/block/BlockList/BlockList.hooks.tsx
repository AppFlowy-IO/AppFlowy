import { useCallback, useEffect, useState } from 'react';
import { debounce } from '@/appflowy_app/utils/tool';
import { BlockEditor } from '@/appflowy_app/block_editor';
import { TreeNode } from '$app/block_editor/tree_node';
import { Alert } from '@mui/material';
import { FallbackProps } from 'react-error-boundary';
import { TextBlockManager } from '../../../block_editor/text_block';
import { TextBlockContext } from '@/appflowy_app/utils/slate/context';

const RESIZE_DELAY = 200;
export interface BlockListProps {
  blockId: string;
  blockEditor: BlockEditor;
}

export function useBlockList({ blockId, blockEditor }: BlockListProps) {
  const [root, setRoot] = useState<TreeNode | null>(null);

  const [version, forceUpdate] = useState<number>(0);

  const buildDeepTree = useCallback(() => {
    const treeNode = blockEditor.renderTree.buildDeep(blockId);
    setRoot(treeNode);
  }, [blockEditor]);

  useEffect(() => {
    buildDeepTree();

    return () => {
      console.log('off');
    };
  }, [blockId, blockEditor, buildDeepTree]);

  useEffect(() => {
    root?.registerUpdate(() => forceUpdate((prev) => prev + 1));

    return () => {
      root?.unregisterUpdate();
    };
  }, [root]);

  useEffect(() => {
    const resize = debounce(() => {
      blockEditor.renderTree.updateViewportBlocks();
    }, RESIZE_DELAY);

    window.addEventListener('resize', resize);

    return () => {
      window.removeEventListener('resize', resize);
    };
  }, []);

  console.log('==== build tree ====', root);

  return {
    root,
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
