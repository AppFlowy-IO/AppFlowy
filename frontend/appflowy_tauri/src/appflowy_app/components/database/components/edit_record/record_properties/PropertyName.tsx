import React, { useRef } from 'react';
import { Property } from '$app/components/database/components/property';
import { Field as FieldType } from '$app/application/database';

interface Props {
  field: FieldType;
  menuOpened?: boolean;
  onOpenMenu?: () => void;
  onCloseMenu?: () => void;
}
function PropertyName({ field, menuOpened = false, onOpenMenu, onCloseMenu }: Props) {
  const ref = useRef<HTMLDivElement | null>(null);

  return (
    <>
      <div
        ref={ref}
        onContextMenu={(e) => {
          e.stopPropagation();
          e.preventDefault();
          onOpenMenu?.();
        }}
        className={'flex min-h-[36px] w-[200px] cursor-pointer items-center'}
        onClick={onOpenMenu}
      >
        <Property menuOpened={menuOpened} onOpenMenu={onOpenMenu} onCloseMenu={onCloseMenu} field={field} />
      </div>
    </>
  );
}

export default PropertyName;
