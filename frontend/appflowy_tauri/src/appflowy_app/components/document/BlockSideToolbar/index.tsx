import React, { useContext } from 'react';
import { useBlockSideToolbar, usePopover } from './BlockSideToolbar.hooks';
import Portal from '../BlockPortal';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import Popover from '@mui/material/Popover';
import DragIndicatorRoundedIcon from '@mui/icons-material/DragIndicatorRounded';
import AddSharpIcon from '@mui/icons-material/AddSharp';
import BlockMenu from './BlockMenu';
import ToolbarButton from './ToolbarButton';
import { rectSelectionActions } from '$app_reducers/document/slice';
import { addBlockBelowClickThunk } from '$app_reducers/document/async-actions/menu';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';

export default function BlockSideToolbar({ container }: { container: HTMLDivElement }) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
  const { nodeId, style, ref } = useBlockSideToolbar({ container });
  const isDragging = useAppSelector((state) => state.documentRange.isDragging || state.documentRectSelection.isDragging);
  const { handleOpen, ...popoverProps } = usePopover();

  // prevent popover from showing when anchorEl is not in DOM
  const showPopover = popoverProps.anchorEl ? document.contains(popoverProps.anchorEl) : true;

  if (!nodeId || isDragging) return null;

  return (
    <>
      <Portal blockId={nodeId}>
        <div
          ref={ref}
          style={{
            opacity: 0,
            ...style,
          }}
          className='absolute left-[-50px] inline-flex h-[calc(1.5em_+_3px)] transition-opacity duration-500'
          onMouseDown={(e) => {
            // prevent toolbar from taking focus away from editor
            e.preventDefault();
            e.stopPropagation();
          }}
        >
          {/** Add Block below */}
          <ToolbarButton
            tooltip={'Add a new block below'}
            onClick={(e: React.MouseEvent<HTMLButtonElement>) => {
              if (!nodeId || !controller) return;
              dispatch(
                addBlockBelowClickThunk({
                  id: nodeId,
                  controller,
                })
              );
            }}
          >
            <AddSharpIcon />
          </ToolbarButton>

          {/** Open menu or drag */}
          <ToolbarButton
            tooltip={'Click to open Menu'}
            onClick={(e: React.MouseEvent<HTMLButtonElement>) => {
              if (!nodeId) return;
              dispatch(rectSelectionActions.setSelectionById(nodeId));
              handleOpen(e);
            }}
          >
            <DragIndicatorRoundedIcon />
          </ToolbarButton>
        </div>
      </Portal>

      {showPopover && (
        <Popover {...popoverProps}>
          <BlockMenu id={nodeId} onClose={popoverProps.onClose} />
        </Popover>
      )}
    </>
  );
}
