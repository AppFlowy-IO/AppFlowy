import React, { MouseEvent, useState } from 'react';
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
  const [anchorEl, setAnchorEl] = useState<null | HTMLDivElement>(null);

  const open = isHovered && menuOpened && Boolean(anchorEl);

  return (
    <>
      <MenuItem
        title='Turn into'
        isHovered={isHovered}
        icon={<Transform />}
        extra={<ArrowRight />}
        onHover={(e) => {
          setAnchorEl(e.currentTarget as HTMLDivElement);
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
        anchorEl={anchorEl}
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
