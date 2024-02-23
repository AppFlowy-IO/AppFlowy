import React, { useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useBlockActionsToolbar } from './BlockActionsToolbar.hooks';
import BlockActions from '$app/components/editor/components/tools/block_actions/BlockActions';

import { getBlockCssProperty } from '$app/components/editor/components/tools/block_actions/utils';
import BlockOperationMenu from '$app/components/editor/components/tools/block_actions/BlockOperationMenu';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { PopoverProps } from '@mui/material/Popover';

import { EditorSelectedBlockContext } from '$app/components/editor/stores/selected';
import withErrorBoundary from '$app/components/_shared/error_boundary/withError';

const Toolbar = () => {
  const ref = useRef<HTMLDivElement | null>(null);
  const [openContextMenu, setOpenContextMenu] = useState(false);
  const { node } = useBlockActionsToolbar(ref, openContextMenu);
  const cssProperty = node && getBlockCssProperty(node);
  const selectedBlockContext = useContext(EditorSelectedBlockContext);
  const popoverPropsRef = useRef<Partial<PopoverProps> | undefined>(undefined);
  const editor = useSlateStatic();

  const handleOpen = useCallback(() => {
    if (!node || !node.blockId) return;
    setOpenContextMenu(true);
    const path = ReactEditor.findPath(editor, node);

    editor.select(path);
    selectedBlockContext.clear();
    selectedBlockContext.add(node.blockId);
  }, [editor, node, selectedBlockContext]);

  const handleClose = useCallback(() => {
    setOpenContextMenu(false);
    selectedBlockContext.clear();
  }, [selectedBlockContext]);

  useEffect(() => {
    if (!node) return;
    const nodeDom = ReactEditor.toDOMNode(editor, node);
    const onContextMenu = (e: MouseEvent) => {
      e.preventDefault();
      e.stopPropagation();
      const { clientX, clientY } = e;

      popoverPropsRef.current = {
        transformOrigin: {
          vertical: 'top',
          horizontal: 'left',
        },
        anchorReference: 'anchorPosition',
        anchorPosition: {
          top: clientY,
          left: clientX,
        },
      };

      handleOpen();
    };

    nodeDom.addEventListener('contextmenu', onContextMenu);

    return () => {
      nodeDom.removeEventListener('contextmenu', onContextMenu);
    };
  }, [editor, handleOpen, node]);
  return (
    <>
      <div
        ref={ref}
        contentEditable={false}
        className={`block-actions absolute z-10 flex w-[64px] flex-grow transform items-center justify-end px-1 opacity-0 ${cssProperty}`}
      >
        {/* Ensure the toolbar in middle */}
        <div className={`invisible`}>$</div>
        {
          <BlockActions
            node={node || undefined}
            onClickDrag={(e: React.MouseEvent<HTMLButtonElement>) => {
              const target = e.currentTarget;
              const rect = target.getBoundingClientRect();

              popoverPropsRef.current = {
                transformOrigin: {
                  vertical: 'center',
                  horizontal: 'right',
                },
                anchorReference: 'anchorPosition',
                anchorPosition: {
                  top: rect.top + rect.height / 2,
                  left: rect.left,
                },
              };

              handleOpen();
            }}
          />
        }
      </div>
      {node && openContextMenu && (
        <BlockOperationMenu node={node} open={openContextMenu} onClose={handleClose} {...popoverPropsRef.current} />
      )}
    </>
  );
};

export const BlockActionsToolbar = withErrorBoundary(Toolbar);
