import React, { useCallback, useState } from 'react';
import { List, MenuItem, Popover, Portal, Theme } from '@mui/material';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { SxProps } from '@mui/system';

interface ButtonPopoverListProps {
  isVisible: boolean;
  children: React.ReactNode;
  popoverOptions: {
    key: React.Key;
    icon: React.ReactNode;
    label: React.ReactNode | string;
    onClick: () => void;
  }[];
  popoverOrigin: {
    anchorOrigin: PopoverOrigin;
    transformOrigin: PopoverOrigin;
  };
  onClose?: () => void;
  sx?: SxProps<Theme>;
}

function ButtonPopoverList({ popoverOrigin, isVisible, children, popoverOptions, onClose, sx }: ButtonPopoverListProps) {
  const [anchorEl, setAnchorEl] = useState<HTMLDivElement>();
  const open = Boolean(anchorEl);
  const visible = isVisible || open;
  const handleClick = (event: React.MouseEvent<HTMLDivElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = useCallback(() => {
    setAnchorEl(undefined);
  }, []);

  return (
    <>
      {visible && <div onClick={handleClick}>{children}</div>}
      <Portal>
        <Popover
          open={open}
          {...popoverOrigin}
          anchorEl={anchorEl}
          onClose={() => {
            handleClose();
            onClose?.();
          }}
        >
          <List sx={{ ...sx }}>
            {popoverOptions.map((option) => (
              <MenuItem
                key={option.key}
                onClick={() => {
                  option.onClick();
                  handleClose();
                }}
              >
                <span className={'mr-2'}>{option.icon}</span>
                <span>{option.label}</span>
              </MenuItem>
            ))}
          </List>
        </Popover>
      </Portal>
    </>
  );
}

export default ButtonPopoverList;
