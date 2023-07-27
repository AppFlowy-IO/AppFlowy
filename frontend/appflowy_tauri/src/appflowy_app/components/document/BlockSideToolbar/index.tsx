import React from 'react';
import { useBlockSideToolbar, usePopover } from './BlockSideToolbar.hooks';
import { useAppDispatch } from '$app/stores/store';
import Popover from '@mui/material/Popover';
import DragIndicatorRoundedIcon from '@mui/icons-material/DragIndicatorRounded';
import AddSharpIcon from '@mui/icons-material/AddSharp';
import BlockMenu from './BlockMenu';
import { addBlockBelowClickThunk } from '$app_reducers/document/async-actions/menu';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { setRectSelectionThunk } from '$app_reducers/document/async-actions/rect_selection';
import { useTranslation } from 'react-i18next';
import { IconButton } from '@mui/material';
import Tooltip from '@mui/material/Tooltip';

export default function BlockSideToolbar({ id }: { id: string }) {
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();
  const { t } = useTranslation();

  const { handleOpen, open, ...popoverProps } = usePopover();
  const { opacity, topOffset } = useBlockSideToolbar(id);

  const show = opacity === 1 || open;

  return (
    <>
      <div
        style={{
          opacity: show ? 1 : 0,
          top: topOffset,
        }}
        className='absolute left-[-50px] inline-flex transition-opacity duration-100'
      >
        {/** Add Block below */}
        <Tooltip disableInteractive={true} title={t('blockActions.addBelowTooltip')} placement={'top-start'}>
          <IconButton
            style={{
              pointerEvents: show ? 'auto' : 'none',
            }}
            onClick={(_: React.MouseEvent<HTMLButtonElement>) => {
              dispatch(
                addBlockBelowClickThunk({
                  id,
                  controller,
                })
              );
            }}
            sx={{
              height: 24,
              width: 24,
            }}
            onMouseDown={(e) => {
              e.preventDefault();
              e.stopPropagation();
            }}
          >
            <AddSharpIcon />
          </IconButton>
        </Tooltip>

        {/** Open menu or drag */}
        <Tooltip
          disableInteractive={true}
          title={
            <div className={'flex flex-col items-center justify-center'}>
              <div>{t('blockActions.dragTooltip')}</div>
              <div>{t('blockActions.openMenuTooltip')}</div>
            </div>
          }
          placement={'top-start'}
        >
          <IconButton
            style={{
              pointerEvents: show ? 'auto' : 'none',
            }}
            data-draggable-anchor={id}
            onClick={(e: React.MouseEvent<HTMLButtonElement>) => {
              dispatch(
                setRectSelectionThunk({
                  docId,
                  selection: [id],
                })
              );

              handleOpen(e);
            }}
            sx={{
              height: 24,
              width: 24,
            }}
            onMouseDown={(e) => {
              e.preventDefault();
              e.stopPropagation();
            }}
          >
            <DragIndicatorRoundedIcon />
          </IconButton>
        </Tooltip>
      </div>

      <Popover open={open} {...popoverProps}>
        <BlockMenu id={id} onClose={popoverProps.onClose} />
      </Popover>
    </>
  );
}
