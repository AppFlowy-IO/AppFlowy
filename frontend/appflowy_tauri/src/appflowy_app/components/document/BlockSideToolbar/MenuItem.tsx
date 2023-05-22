import React from 'react';
import { ListItem, ListItemButton, ListItemIcon, ListItemText } from '@mui/material';

function MenuItem({
  icon,
  title,
  onClick,
  extra,
  onHover,
}: {
  title: string;
  icon: React.ReactNode;
  onClick?: () => void;
  extra?: React.ReactNode;
  onHover?: (isHovered: boolean, event: React.MouseEvent<HTMLDivElement>) => void;
}) {
  return (
    <ListItem disablePadding>
      <ListItemButton
        onMouseEnter={(e) => onHover?.(true, e)}
        onMouseLeave={(e) => onHover?.(false, e)}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onClick?.();
        }}
      >
        <ListItemIcon>{icon}</ListItemIcon>
        <ListItemText primary={title} />
        {extra}
      </ListItemButton>
    </ListItem>
  );
}

export default MenuItem;
