import React, { useState } from 'react';
import { Align } from '$app/interfaces/document';
import ImageAlign from '$app/components/document/ImageBlock/ImageAlign';
import { DeleteOutline } from '@mui/icons-material';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { deleteNodeThunk } from '$app_reducers/document/async-actions';
import { useTranslation } from 'react-i18next';
import Tooltip from '@mui/material/Tooltip';

function ImageToolbar({ id, open, align }: { id: string; open: boolean; align: Align }) {
  const [popoverOpen, setPopoverOpen] = useState(false);
  const visible = open || popoverOpen;
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();

  const { t } = useTranslation();

  return (
    <>
      <div
        className={`${
          visible ? 'opacity-1 pointer-events-auto' : 'pointer-events-none opacity-0'
        } absolute right-2 top-2 z-[1px] flex h-[26px] max-w-[calc(100%-16px)] cursor-pointer items-center justify-center whitespace-nowrap rounded bg-bg-body text-sm text-text-title transition-opacity`}
      >
        <ImageAlign id={id} align={align} onOpen={() => setPopoverOpen(true)} onClose={() => setPopoverOpen(false)} />
        <Tooltip disableInteractive placement={'top'} title={t('button.delete')}>
          <div
            onClick={() => {
              void dispatch(deleteNodeThunk({ id, controller }));
            }}
            className='flex items-center justify-center p-1'
          >
            <DeleteOutline />
          </div>
        </Tooltip>
      </div>
    </>
  );
}

export default ImageToolbar;
