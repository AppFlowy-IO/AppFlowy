import React, { forwardRef } from 'react';
import IconButton, { IconButtonProps } from '@mui/material/IconButton';
import { Tooltip } from '@mui/material';

const ActionButton = forwardRef<
  HTMLButtonElement,
  {
    tooltip?: string | React.ReactNode;
    onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
    children: React.ReactNode;
    active?: boolean;
  } & IconButtonProps
>(({ tooltip, onClick, disabled, children, active, className, ...props }, ref) => {
  return (
    <Tooltip disableInteractive={true} placement={'top'} title={tooltip}>
      <IconButton
        ref={ref}
        onClick={onClick}
        size={'small'}
        style={{
          color: active ? 'var(--fill-default)' : disabled ? 'var(--line-on-toolbar)' : undefined,
        }}
        disabled={disabled}
        {...props}
        className={`${
          className ?? ''
        } bg-transparent px-1 py-1 text-icon-on-toolbar hover:bg-transparent hover:text-fill-hover`}
      >
        {children}
      </IconButton>
    </Tooltip>
  );
});

export default ActionButton;
