import React, { HTMLAttributes, PropsWithChildren } from 'react';

export interface CellTextProps {
  className?: string;
}

export const CellText = React.forwardRef<HTMLDivElement, PropsWithChildren<HTMLAttributes<HTMLDivElement>>>(function CellText(props, ref) {
  const { children, className, ...other } = props;

  return (
    <div
      ref={ref}
      className={['flex p-2', className].join(' ')}
      {...other}
    >
      <span className="flex-1 text-sm truncate">
        {children}
      </span>
    </div>
  );
});
