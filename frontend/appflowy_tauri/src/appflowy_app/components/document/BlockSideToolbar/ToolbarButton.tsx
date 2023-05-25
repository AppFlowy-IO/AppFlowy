import React from 'react';
const sx = { height: 24, width: 24 };
import { IconButton } from '@mui/material';
import Tooltip from '@mui/material/Tooltip';

const ToolbarButton = ({
  onClick,
  children,
  tooltip,
}: {
  tooltip: string;
  children: React.ReactNode;
  onClick: React.MouseEventHandler<HTMLButtonElement>;
}) => {
  return (
    <Tooltip title={tooltip} placement={'top-start'}>
      <IconButton onClick={onClick} sx={sx}>
        {children}
      </IconButton>
    </Tooltip>
  );
};

export default ToolbarButton;
