import React, { MouseEvent, useEffect, useRef } from 'react';
import { ArrowRight, Transform } from '@mui/icons-material';
import MenuItem from '$app/components/document/_shared/MenuItem';
import TurnIntoPopover from '$app/components/document/_shared/TurnInto';

function BlockMenuTurnInto({
  id,
  onClose,
  onHovered,
  isHovered,
  menuOpened,
  label,
}: {
  id: string;
  onClose: () => void;
  onHovered: (e: MouseEvent) => void;
  isHovered: boolean;
  menuOpened: boolean;
  label?: string;
}) {
  const ref = useRef<HTMLDivElement | null>(null);
  const [anchorPosition, setAnchorPosition] = React.useState<{ top: number; left: number }>();
  const open = Boolean(anchorPosition);

  useEffect(() => {
    if (isHovered && menuOpened) {
      const rect = ref.current?.getBoundingClientRect();

      if (!rect) return;
      setAnchorPosition({
        top: rect.top + rect.height / 2,
        left: rect.left + rect.width,
      });
    } else {
      setAnchorPosition(undefined);
    }
  }, [isHovered, menuOpened]);
  return (
    <>
      <MenuItem
        ref={ref}
        title={label}
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
        onOk={() => onClose()}
        onClose={() => {
          setAnchorPosition(undefined);
        }}
        anchorReference={'anchorPosition'}
        anchorPosition={anchorPosition}
        transformOrigin={{
          vertical: 'center',
          horizontal: 'left',
        }}
      />
    </>
  );
}

export default BlockMenuTurnInto;
