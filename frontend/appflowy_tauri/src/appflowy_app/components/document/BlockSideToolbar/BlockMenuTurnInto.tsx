import React, { MouseEvent, useRef } from 'react';
import { ArrowRight, Transform } from '@mui/icons-material';
import MenuItem from '$app/components/document/_shared/MenuItem';
import TurnIntoPopover from '$app/components/document/_shared/TurnInto';

function BlockMenuTurnInto({
  id,
  onClose,
  onHovered,
  isHovered,
  menuOpened,
}: {
  id: string;
  onClose: () => void;
  onHovered: (e: MouseEvent) => void;
  isHovered: boolean;
  menuOpened: boolean;
}) {
  const ref = useRef<HTMLDivElement | null>(null);
  const open = isHovered && menuOpened && Boolean(ref.current);

  return (
    <>
      <MenuItem
        ref={ref}
        title='Turn into'
        isHovered={isHovered}
        icon={<Transform />}
        extra={<ArrowRight />}
        onHover={(e) => {
          onHovered(e);
        }}
      />
      <TurnIntoPopover
        id={id}
        open={open}
        disableRestoreFocus
        disableAutoFocus
        sx={{
          pointerEvents: 'none',
        }}
        PaperProps={{
          style: {
            pointerEvents: 'auto',
          },
        }}
        onClose={onClose}
        anchorEl={ref.current}
        anchorOrigin={{
          vertical: 'center',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'center',
          horizontal: 'left',
        }}
      />
    </>
  );
}

export default BlockMenuTurnInto;
