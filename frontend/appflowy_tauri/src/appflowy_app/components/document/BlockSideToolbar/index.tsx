import React, { useCallback, useState } from 'react';
import { PopoverType, useBlockSideToolbar, usePopover } from './BlockSideToolbar.hooks';
import Portal from '../BlockPortal';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import Popover from '@mui/material/Popover';
import DragIndicatorRoundedIcon from '@mui/icons-material/DragIndicatorRounded';
import AddSharpIcon from '@mui/icons-material/AddSharp';
import ToolbarButton from './ToolbarButton';
import AddBelowMenu from './AddBelowMenu';
import BlockMenu from './BlockMenu';
import { rectSelectionActions } from '$app_reducers/document/slice';

export default function BlockSideToolbar({ container }: { container: HTMLDivElement }) {
  const dispatch = useAppDispatch();
  const { nodeId, style, ref } = useBlockSideToolbar({ container });
  const isDragging = useAppSelector(
    (state) => state.documentRangeSelection.isDragging || state.documentRectSelection.isDragging
  );
  const [type, setType] = useState<PopoverType>();
  const { handleOpen, ...popoverProps } = usePopover(type);

  const renderPopoverContent = useCallback(() => {
    if (!nodeId || !type) return null;

    if (type === PopoverType.AddBelowMenu) {
      return <AddBelowMenu id={nodeId} onClose={popoverProps.onClose} />;
    }
    if (type === PopoverType.BlockMenu) {
      return <BlockMenu id={nodeId} onClose={popoverProps.onClose} />;
    }
    return null;
  }, [nodeId, popoverProps.onClose, type]);

  const triggerOpen = useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!nodeId) return;
      dispatch(rectSelectionActions.setSelectionById(nodeId));
      handleOpen(e);
    },
    [dispatch, handleOpen, nodeId]
  );

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
            onClick={(e) => {
              setType(PopoverType.AddBelowMenu);
              triggerOpen(e);
            }}
          >
            <AddSharpIcon />
          </ToolbarButton>

          {/** Open menu or drag */}
          <ToolbarButton
            tooltip={'Click to open Menu'}
            onClick={(e) => {
              setType(PopoverType.BlockMenu);
              triggerOpen(e);
            }}
          >
            <DragIndicatorRoundedIcon />
          </ToolbarButton>
        </div>
      </Portal>

      {showPopover && <Popover {...popoverProps}>{renderPopoverContent()}</Popover>}
    </>
  );
}
