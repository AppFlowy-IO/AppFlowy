import React from 'react';
import { Popover as PopoverComponent, PopoverProps as PopoverComponentProps } from '@mui/material';

const defaultProps: Partial<PopoverComponentProps> = {
  keepMounted: false,
  disableRestoreFocus: true,
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
};

export function Popover({ children, ...props }: PopoverComponentProps) {
  return (
    <PopoverComponent {...defaultProps} {...props}>
      {children}
    </PopoverComponent>
  );
}
