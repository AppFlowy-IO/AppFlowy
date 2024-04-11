import { FC, useEffect, useRef, useState } from 'react';
import { Field as FieldType } from '$app/application/database';
import { ProppertyTypeSvg } from './property_type/ProppertyTypeSvg';
import { PropertyMenu } from '$app/components/database/components/property/PropertyMenu';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';
import { PopoverOrigin } from '@mui/material/Popover/Popover';

export interface FieldProps {
  field: FieldType;
  menuOpened?: boolean;
  onOpenMenu?: (id: string) => void;
  onCloseMenu?: (id: string) => void;
  className?: string;
}

const initialAnchorOrigin: PopoverOrigin = {
  vertical: 'bottom',
  horizontal: 'right',
};

const initialTransformOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'center',
};

export const Property: FC<FieldProps> = ({ field, onCloseMenu, className, menuOpened }) => {
  const ref = useRef<HTMLDivElement | null>(null);
  const [anchorPosition, setAnchorPosition] = useState<
    | {
        top: number;
        left: number;
        height: number;
      }
    | undefined
  >(undefined);

  const open = Boolean(anchorPosition && menuOpened);

  useEffect(() => {
    if (menuOpened) {
      const rect = ref.current?.getBoundingClientRect();

      if (rect) {
        setAnchorPosition({
          top: rect.top + 28,
          left: rect.left,
          height: rect.height,
        });
        return;
      }
    }

    setAnchorPosition(undefined);
  }, [menuOpened]);

  const { paperHeight, paperWidth, transformOrigin, anchorOrigin, isEntered } = usePopoverAutoPosition({
    initialPaperWidth: 300,
    initialPaperHeight: 400,
    anchorPosition,
    initialAnchorOrigin,
    initialTransformOrigin,
    open,
  });

  return (
    <>
      <div ref={ref} className={className ? className : `flex w-full items-center px-2`}>
        <ProppertyTypeSvg className='mr-1 text-base' type={field.type} />
        <span className='flex-1 truncate text-left text-xs'>{field.name}</span>
      </div>

      {open && (
        <PropertyMenu
          field={field}
          open={open && isEntered}
          onClose={() => {
            onCloseMenu?.(field.id);
          }}
          transformOrigin={transformOrigin}
          anchorOrigin={anchorOrigin}
          PaperProps={{
            style: {
              maxHeight: paperHeight,
              width: paperWidth,
              height: 'auto',
            },
            className: 'flex h-full flex-col overflow-hidden',
          }}
          anchorPosition={anchorPosition}
          anchorReference={'anchorPosition'}
        />
      )}
    </>
  );
};
