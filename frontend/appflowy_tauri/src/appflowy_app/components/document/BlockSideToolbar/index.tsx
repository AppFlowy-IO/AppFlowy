import React from 'react';
import { useBlockSideToolbar, usePopover } from './BlockSideToolbar.hooks';
import Portal from '../BlockPortal';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import Popover from '@mui/material/Popover';
import DragIndicatorRoundedIcon from '@mui/icons-material/DragIndicatorRounded';
import AddSharpIcon from '@mui/icons-material/AddSharp';
import BlockMenu from './BlockMenu';
import ToolbarButton from './ToolbarButton';
import { addBlockBelowClickThunk } from '$app_reducers/document/async-actions/menu';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { RANGE_NAME, RECT_RANGE_NAME } from '$app/constants/document/name';
import { setRectSelectionThunk } from '$app_reducers/document/async-actions/rect_selection';
import { useTranslation } from 'react-i18next';

export default function BlockSideToolbar({ container }: { container: HTMLDivElement }) {
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();
  const { t } = useTranslation();

  const { nodeId, style, ref } = useBlockSideToolbar({ container });
  const isDragging = useAppSelector(
    (state) => state[RANGE_NAME][docId]?.isDragging || state[RECT_RANGE_NAME][docId]?.isDragging
  );
  const { handleOpen, ...popoverProps } = usePopover();

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
            tooltip={t('tooltip.addBlockBelow')}
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
            tooltip={t('tooltip.openMenu')}
            onClick={(e: React.MouseEvent<HTMLButtonElement>) => {
              if (!nodeId) return;
              dispatch(
                setRectSelectionThunk({
                  docId,
                  selection: [nodeId],
                })
              );

              handleOpen(e);
            }}
          >
            <DragIndicatorRoundedIcon />
          </ToolbarButton>
        </div>
      </Portal>

      <Popover {...popoverProps}>
        <BlockMenu id={nodeId} onClose={popoverProps.onClose} />
      </Popover>
    </>
  );
}
