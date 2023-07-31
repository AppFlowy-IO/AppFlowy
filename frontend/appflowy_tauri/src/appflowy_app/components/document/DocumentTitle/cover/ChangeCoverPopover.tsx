import React, { useRef } from 'react';
import Popover from '@mui/material/Popover';
import ChangeColors from '$app/components/document/DocumentTitle/cover/ChangeColors';
import ChangeImages from '$app/components/document/DocumentTitle/cover/ChangeImages';
import { CoverType } from '$app/interfaces/document';

function ChangeCoverPopover({
  open,
  anchorPosition,
  onClose,
  cover,
  onUpdateCover,
}: {
  open: boolean;
  anchorPosition?: { top: number; left: number };
  onClose: () => void;
  coverType: CoverType;
  cover: string;
  onUpdateCover: (coverType: CoverType, cover: string) => void;
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
            onUpdateCover(CoverType.Color, color);
          }}
          cover={cover}
        />
        <ChangeImages cover={cover} onChange={(url) => onUpdateCover(CoverType.Image, url)} />
      </div>
    </Popover>
  );
}

export default ChangeCoverPopover;
