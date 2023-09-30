import React, { forwardRef, MouseEvent, useMemo } from 'react';
import { MenuItem as MuiMenuItem } from '@mui/material';

const MenuItem = forwardRef(function (
  {
    id,
    icon,
    title,
    onClick,
    extra,
    onHover,
    isHovered,
    className,
    iconSize,
    desc,
  }: {
    id?: string;
    className?: string;
    title?: string;
    desc?: string;
    icon: React.ReactNode;
    onClick?: () => void;
    extra?: React.ReactNode;
    isHovered?: boolean;
    onHover?: (e: MouseEvent) => void;
    iconSize?: {
      width: number;
      height: number;
    };
  },
  ref: React.ForwardedRef<HTMLDivElement>
) {
  const imgSize = useMemo(() => iconSize || { width: 50, height: 50 }, [iconSize]);

  return (
    <div className={className} ref={ref} id={id}>
      <MuiMenuItem
        sx={{
          borderRadius: '4px',
          padding: '4px 8px',
          fontSize: 14,
        }}
        selected={isHovered}
        onMouseEnter={(e) => {
          onHover?.(e);
        }}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onClick?.();
        }}
      >
        <div
          style={{
            width: imgSize.width,
            height: imgSize.height,
          }}
          className={`mr-2 flex items-center justify-center rounded border border-line-divider`}
        >
          {icon}
        </div>
        <div className={'flex flex-1 flex-col'}>
          <div className={'text-sm'}>{title}</div>
          {desc && (
            <div
              className={'font-normal text-text-caption'}
              style={{
                fontSize: '0.85em',
                fontWeight: 300,
              }}
            >
              {desc}
            </div>
          )}
        </div>
        <div>{extra}</div>
      </MuiMenuItem>
    </div>
  );
});

export default MenuItem;
