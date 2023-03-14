import { useCallback, useEffect, useState } from 'react';
import { debounce } from '@/appflowy_app/utils/tool';
import { BlockEditor } from '@/appflowy_app/block_editor';
import { TreeNode } from '$app/block_editor/tree_node';
import { Block } from '@/appflowy_app/block_editor/block';
import { SelectionContext } from '@/appflowy_app/utils/block';
import { Alert } from '@mui/material';
import { FallbackProps } from 'react-error-boundary';

const RESIZE_DELAY = 200;

export interface BlockListProps {
  blockId: string;
  blockEditor: BlockEditor;
  onSelectionChange?: ({ focusNodeId }: { focusNodeId: string }) => void;
}

export function useBlockList({ blockId, blockEditor, onSelectionChange }: BlockListProps) {
  const [root, setRoot] = useState<TreeNode | null>(null);

  const buildTree = useCallback(() => {
    const treeNode = blockEditor.renderTree.build(blockId);
    setRoot(treeNode);
    console.log('==== build tree ====', treeNode);
  }, [blockEditor]);

  useEffect(() => {
    const blockChange = (info: {
      command: string;
      data: {
        block: Block;
        oldParentId?: string;
        oldPrevId?: string;
      };
    }) => {
      const { command, data } = info;
      const { block } = data;
      buildTree();
      if (block?.id) {
        if (command === 'insert') {
          onSelectionChange?.({
            focusNodeId: block.id,
          });
        }
        blockEditor.renderTree.updateBlockPosition(block?.id, true);
      }
    };

    buildTree();
    blockEditor.event.on('block_change', blockChange);

    return () => {
      console.log('off');
      blockEditor.event.off('block_change', blockChange);
    };
  }, [blockId, blockEditor, buildTree]);

  useEffect(() => {
    const resize = debounce(() => {
      // update rect cache when window resized
    }, RESIZE_DELAY);

    window.addEventListener('resize', resize);

    return () => {
      window.removeEventListener('resize', resize);
    };
  }, []);

  return {
    root,
  };
}

export function withSelection<P extends BlockListProps>(BaseComponent: React.ComponentType<P>) {
  return (props: P) => {
    const [focusNode, setFocusNode] = useState<string>('');
    return (
      <SelectionContext.Provider
        value={{
          focusNodeId: focusNode,
        }}
      >
        <BaseComponent
          {...{
            ...props,
            onSelectionChange: ({ focusNodeId }: { focusNodeId: string }) => {
              setFocusNode(focusNodeId);
            },
          }}
        />
      </SelectionContext.Provider>
    );
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
