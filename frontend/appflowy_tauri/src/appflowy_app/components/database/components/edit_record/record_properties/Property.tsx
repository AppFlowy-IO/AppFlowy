import React, { HTMLAttributes } from 'react';
import PropertyName from '$app/components/database/components/edit_record/record_properties/PropertyName';
import PropertyValue from '$app/components/database/components/edit_record/record_properties/PropertyValue';
import { Field } from '$app/components/database/application';
import { IconButton, Tooltip } from '@mui/material';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import { useTranslation } from 'react-i18next';

interface Props extends HTMLAttributes<HTMLDivElement> {
  field: Field;
  rowId: string;
  ishovered: boolean;
  onHover: (id: string | null) => void;
  menuOpened?: boolean;
  onOpenMenu?: () => void;
  onCloseMenu?: () => void;
}

function Property(
  { field, rowId, ishovered, onHover, menuOpened, onCloseMenu, onOpenMenu, ...props }: Props,
  ref: React.ForwardedRef<HTMLDivElement>
) {
  const { t } = useTranslation();

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
        className={'relative flex items-start gap-6 rounded hover:bg-content-blue-50'}
        key={field.id}
        {...props}
      >
        <PropertyName menuOpened={menuOpened} onCloseMenu={onCloseMenu} onOpenMenu={onOpenMenu} field={field} />
        <PropertyValue rowId={rowId} field={field} />
        {ishovered && (
          <div className={`absolute left-[-30px] flex h-full items-center `}>
            <Tooltip placement='top' title={t('grid.row.dragAndClick')}>
              <IconButton onClick={onOpenMenu} className='mx-1 cursor-grab active:cursor-grabbing'>
                <DragSvg />
              </IconButton>
            </Tooltip>
          </div>
        )}
      </div>
    </>
  );
}

export default React.forwardRef(Property);
