import { PopoverProps } from '@mui/material/Popover';

export const PopoverCommonProps: Partial<PopoverProps> = {
  keepMounted: false,
  disableAutoFocus: true,
  disableEnforceFocus: true,
  disableRestoreFocus: true,
};

export const PopoverPreventBlurProps: Partial<PopoverProps> = {
  ...PopoverCommonProps,

  onMouseDown: (e) => {
    // prevent editor blur
    e.preventDefault();
    e.stopPropagation();
  },
};

export const PopoverNoBackdropProps: Partial<PopoverProps> = {
  ...PopoverCommonProps,
  sx: {
    pointerEvents: 'none',
  },
  PaperProps: {
    style: {
      pointerEvents: 'auto',
    },
  },
  onMouseDown: (e) => {
    // prevent editor blur
    e.stopPropagation();
  },
};
