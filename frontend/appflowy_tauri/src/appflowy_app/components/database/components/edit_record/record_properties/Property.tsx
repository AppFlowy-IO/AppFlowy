import React, { HTMLAttributes, useCallback, useState } from 'react';
import PropertyName from '$app/components/database/components/edit_record/record_properties/PropertyName';
import PropertyValue from '$app/components/database/components/edit_record/record_properties/PropertyValue';
import { Field } from '$app/components/database/application';
import PropertyActions from '$app/components/database/components/edit_record/record_properties/PropertyActions';

interface Props extends HTMLAttributes<HTMLDivElement> {
  field: Field;
  rowId: string;
  ishovered: boolean;
  onHover: (id: string | null) => void;
}

function Property({ field, rowId, ishovered, onHover, ...props }: Props, ref: React.ForwardedRef<HTMLDivElement>) {
  const [openMenu, setOpenMenu] = useState(false);

  const handleOpenMenu = useCallback(() => {
    setOpenMenu(true);
  }, []);

  const handleCloseMenu = useCallback(() => {
    setOpenMenu(false);
  }, []);

  return (
    <>
      <div
        ref={ref}
        onMouseEnter={() => {
          onHover(field.id);
        }}
        onMouseLeave={() => {
          onHover(null);
        }}
        className={'relative flex gap-6 rounded hover:bg-content-blue-50'}
        key={field.id}
        {...props}
      >
        <PropertyName openMenu={openMenu} onOpenMenu={handleOpenMenu} onCloseMenu={handleCloseMenu} field={field} />
        <PropertyValue rowId={rowId} field={field} />
        {ishovered && <PropertyActions onOpenMenu={handleOpenMenu} />}
      </div>
    </>
  );
}

export default React.memo(React.forwardRef(Property));
