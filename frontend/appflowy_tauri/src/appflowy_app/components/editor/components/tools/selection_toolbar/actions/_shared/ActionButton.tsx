import React, { forwardRef } from 'react';
import IconButton, { IconButtonProps } from '@mui/material/IconButton';
import { Tooltip } from '@mui/material';

const ActionButton = forwardRef<
  HTMLButtonElement,
  {
    tooltip: string;
    onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
    children: React.ReactNode;
    active?: boolean;
  } & IconButtonProps
>(({ tooltip, onClick, children, active, className, ...props }, ref) => {
  return (
    <Tooltip placement={'top'} title={tooltip}>
      <IconButton
        ref={ref}
        onClick={onClick}
        size={'small'}
        style={{
          color: active ? 'var(--fill-default)' : undefined,
        }}
        {...props}
        className={`${className ?? ''} bg-transparent px-1 py-2 text-bg-body hover:bg-transparent hover:text-fill-hover`}
      >
        {children}
      </IconButton>
    </Tooltip>
  );
});

export default ActionButton;
