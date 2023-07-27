import React, { useCallback, useEffect, useRef, useState } from 'react';
import Popover, { PopoverActions } from '@mui/material/Popover';
import ChangeColors from '$app/components/document/DocumentTitle/cover/ChangeColors';
import ChangeImages from '$app/components/document/DocumentTitle/cover/ChangeImages';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

function ChangeCoverPopover({
  open,
  anchorPosition,
  onClose,
  coverType,
  cover,
  onUpdateCover,
}: {
  open: boolean;
  anchorPosition?: { top: number; left: number };
  onClose: () => void;
  coverType: 'image' | 'color';
  cover: string;
  onUpdateCover: (coverType: 'image' | 'color', cover: string) => void;
}) {
  const ref = useRef<HTMLDivElement>(null);

  return (
    <Popover
      open={open}
      anchorReference={'anchorPosition'}
      anchorPosition={anchorPosition}
      onClose={onClose}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'right',
      }}
      PaperProps={{
        sx: {
          height: 'auto',
          overflow: 'visible',
        },
        elevation: 0,
      }}
    >
      <div
        style={{
          boxShadow:
            '0px 5px 5px -3px rgba(0,0,0,0.2),0px 8px 10px 1px rgba(0,0,0,0.14),0px 3px 14px 2px rgba(0,0,0,0.12)',
        }}
        className={'flex flex-col rounded-md bg-bg-body p-4 '}
        ref={ref}
      >
        <ChangeColors
          onChange={(color) => {
            onUpdateCover('color', color);
          }}
          cover={cover}
        />
        <ChangeImages cover={cover} onChange={(url) => onUpdateCover('image', url)} />
      </div>
    </Popover>
  );
}

export default ChangeCoverPopover;
