import { FC, useEffect, useRef, useState } from 'react';
import { Field as FieldType } from '../../application';
import { ProppertyTypeSvg } from './property_type/ProppertyTypeSvg';
import { PropertyMenu } from '$app/components/database/components/property/PropertyMenu';

export interface FieldProps {
  field: FieldType;
  menuOpened?: boolean;
  onOpenMenu?: (id: string) => void;
  onCloseMenu?: (id: string) => void;
}

export const Property: FC<FieldProps> = ({ field, onCloseMenu, menuOpened }) => {
  const ref = useRef<HTMLDivElement | null>(null);
  const [anchorPosition, setAnchorPosition] = useState<
    | {
        top: number;
        left: number;
      }
    | undefined
  >(undefined);

  const open = Boolean(anchorPosition) && menuOpened;

  useEffect(() => {
    if (menuOpened) {
      const rect = ref.current?.getBoundingClientRect();

      if (rect) {
        setAnchorPosition({
          top: rect.top + rect.height,
          left: rect.left,
        });
        return;
      }
    }

    setAnchorPosition(undefined);
  }, [menuOpened]);

  return (
    <>
      <div ref={ref} className='flex w-full items-center px-2'>
        <ProppertyTypeSvg className='mr-1 text-base' type={field.type} />
        <span className='flex-1 truncate text-left text-xs'>{field.name}</span>
      </div>

      {open && (
        <PropertyMenu
          field={field}
          open={open}
          onClose={() => {
            onCloseMenu?.(field.id);
          }}
          anchorPosition={anchorPosition}
          anchorReference={'anchorPosition'}
        />
      )}
    </>
  );
};
