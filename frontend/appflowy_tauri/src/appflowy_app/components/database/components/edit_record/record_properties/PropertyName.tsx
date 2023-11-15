import React, { useRef } from 'react';
import { Field } from '$app/components/database/components/field';
import { Field as FieldType } from '$app/components/database/application';
import { FieldMenu } from '$app/components/database/components/field/FieldMenu';

interface Props {
  field: FieldType;
  openMenu: boolean;
  onOpenMenu: () => void;
  onCloseMenu: () => void;
}
function PropertyName({ field, openMenu, onOpenMenu, onCloseMenu }: Props) {
  const ref = useRef<HTMLDivElement | null>(null);

  return (
    <>
      <div
        ref={ref}
        onContextMenu={(e) => {
          e.stopPropagation();
          e.preventDefault();
          onOpenMenu();
        }}
        className={'flex w-[200px] cursor-pointer items-center'}
        onClick={onOpenMenu}
      >
        <Field field={field} />
      </div>
      {openMenu && <FieldMenu field={field} open={openMenu} anchorEl={ref.current} onClose={onCloseMenu} />}
    </>
  );
}

export default React.memo(PropertyName);
