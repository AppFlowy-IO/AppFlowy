import React, { useState } from 'react';
import { Align } from '$app/interfaces/document';
import ImageAlign from '$app/components/document/ImageBlock/ImageAlign';
import MenuTooltip from '$app/components/document/TextActionMenu/menu/MenuTooltip';
import { DeleteOutline } from '@mui/icons-material';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { deleteNodeThunk } from '$app_reducers/document/async-actions';

function ImageToolbar({ id, open, align }: { id: string; open: boolean; align: Align }) {
  const [popoverOpen, setPopoverOpen] = useState(false);
  const visible = open || popoverOpen;
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();

  return (
    <>
      <div
        className={`${
          visible ? 'opacity-1 pointer-events-auto' : 'pointer-events-none opacity-0'
        } absolute right-2 top-2 z-[1px] flex h-[26px] max-w-[calc(100%-16px)] cursor-pointer items-center justify-center whitespace-nowrap rounded bg-shade-1 bg-opacity-50 text-sm text-white transition-opacity`}
      >
        <ImageAlign id={id} align={align} onOpen={() => setPopoverOpen(true)} onClose={() => setPopoverOpen(false)} />
        <MenuTooltip title={'Delete'}>
          <div
            onClick={() => {
              dispatch(deleteNodeThunk({ id, controller }));
            }}
            className='flex items-center justify-center bg-transparent p-1'
          >
            <DeleteOutline />
          </div>
        </MenuTooltip>
      </div>
    </>
  );
}

export default ImageToolbar;
