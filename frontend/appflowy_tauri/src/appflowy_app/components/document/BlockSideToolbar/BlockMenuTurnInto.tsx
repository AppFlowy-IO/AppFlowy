import React, { useState } from 'react';
import { ArrowRight, Transform } from '@mui/icons-material';
import MenuItem from '$app/components/document/BlockSideToolbar/MenuItem';
import TurnIntoPopover from '$app/components/document/_shared/TurnInto';

function BlockMenuTurnInto({
  id,
  onClose,
  onHovered,
  isHovered,
}: {
  id: string;
  onClose: () => void;
  onHovered: () => void;
  isHovered: boolean;
}) {
  const [anchorEl, setAnchorEl] = useState<null | HTMLDivElement>(null);

  const open = isHovered && Boolean(anchorEl);

  return (
    <>
      <MenuItem
        title='Turn into'
        icon={<Transform />}
        extra={<ArrowRight />}
        onHover={(hovered, event) => {
          if (hovered) {
            onHovered();
            setAnchorEl(event.currentTarget);
            return;
          }
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
