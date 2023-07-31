import React from 'react';
import Tooltip from '@mui/material/Tooltip';

function ToolbarTooltip({ title, children }: { children: JSX.Element; title?: string }) {
  return (
    <Tooltip
      disableInteractive
      slotProps={{ tooltip: { style: { background: 'var(--bg-tips)', borderRadius: 8 } } }}
      title={title}
      placement='top-start'
    >
      <div>{children}</div>
    </Tooltip>
  );
}

export default ToolbarTooltip;
