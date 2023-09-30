import React, { useRef } from 'react';
import Popover from '@mui/material/Popover';
import ChangeColors from '$app/components/document/DocumentBanner/cover/ChangeColors';
import ChangeImages from '$app/components/document/DocumentBanner/cover/ChangeImages';
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
      disableAutoFocus
      disableRestoreFocus
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
            "var(--shadow-resize-popover)",
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
