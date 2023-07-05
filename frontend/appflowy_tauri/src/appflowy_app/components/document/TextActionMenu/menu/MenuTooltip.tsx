import React from 'react';
import Tooltip from '@mui/material/Tooltip';

function MenuTooltip({ title, children }: { children: JSX.Element; title?: string }) {
  return (
    <Tooltip
      slotProps={{ tooltip: { style: { background: '#E0F8FF', borderRadius: 8 } } }}
      title={title}
      placement='top-start'
    >
      <div>{children}</div>
    </Tooltip>
  );
}

export default MenuTooltip;
