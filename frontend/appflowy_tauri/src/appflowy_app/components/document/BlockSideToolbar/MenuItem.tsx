import React from 'react';
import { ListItem, ListItemButton, ListItemIcon, ListItemText } from '@mui/material';

function MenuItem({
  id,
  icon,
  title,
  onClick,
  extra,
  onHover,
  isHovered,
}: {
  id?: string;
  title: string;
  icon: React.ReactNode;
  onClick: () => void;
  extra?: React.ReactNode;
  isHovered: boolean;
  onHover: () => void;
}) {
  return (
    <div id={id}>
      <ListItemButton
        sx={{
          borderRadius: '4px',
          padding: '4px 8px',
          fontSize: 14,
        }}
        selected={isHovered}
        onMouseEnter={(e) => onHover()}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onClick();
        }}
      >
        <div className={'mr-2 flex h-[50px] w-[50px] items-center justify-center rounded border border-shade-5'}>
          {icon}
        </div>
        <div className={'flex flex-col'}>
          <div>{title}</div>
          <div
            className={'font-normal text-shade-4'}
            style={{
              fontSize: '0.85em',
              fontWeight: 300,
            }}
          >
            desc
          </div>
        </div>
        {extra}
      </ListItemButton>
    </div>
  );
}

export default MenuItem;
