import { useCallback, useEffect, useMemo, useState } from 'react';
import { debounce } from '@/appflowy_app/utils/tool';
import { BlockEditor } from '@/appflowy_app/block_editor';
import { TreeNode } from '$app/block_editor/tree_node';
import { Alert } from '@mui/material';
import { FallbackProps } from 'react-error-boundary';
import { BlockChangeProps } from '@/appflowy_app/block_editor/block_chain';

const RESIZE_DELAY = 200;
export interface BlockListProps {
  blockId: string;
  blockEditor: BlockEditor;
}

export function useBlockList({ blockId, blockEditor }: BlockListProps) {
  const [root, setRoot] = useState<TreeNode | null>(null);

  const buildTree = useCallback(() => {
    const treeNode = blockEditor.renderTree.build(blockId);
    setRoot(treeNode);
  }, [blockEditor]);

  const debounceBuildTree = useMemo(() => debounce(buildTree, 100), [buildTree]);

  useEffect(() => {
    const blockChange = (info: { command: string; data: BlockChangeProps }) => {
      const { command, data } = info;
      const { block, startBlock, endBlock } = data;

      switch (command) {
        case 'insert':
          debounceBuildTree();
          if (block) {
            blockEditor.selection.focusBlockStart(block.id);
          }
          break;
        case 'update':
          break;
        case 'move':
          debounceBuildTree();
          break;
        default:
          break;
      }

      if (block) {
        blockEditor.renderTree.updateBlockPosition(block.id);
      }
      if (startBlock && endBlock) {
        blockEditor.renderTree.updateBlockPosition(startBlock.id);
        blockEditor.renderTree.updateBlockPosition(endBlock.id);
      }
    };

    debounceBuildTree();
    blockEditor.event.on('block_change', blockChange);

    return () => {
      console.log('off');
      blockEditor.event.off('block_change', blockChange);
    };
  }, [blockId, blockEditor, debounceBuildTree]);

  useEffect(() => {
    const resize = debounce(() => {
      // update rect cache when window resized
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
