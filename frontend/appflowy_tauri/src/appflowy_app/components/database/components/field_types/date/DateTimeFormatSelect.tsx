import React, { useState, useRef } from 'react';
import { Menu, MenuItem } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { DateTimeField } from '$app/components/database/application';
import DateTimeFormat from '$app/components/database/components/field_types/date/DateTimeFormat';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';

interface Props {
  field: DateTimeField;
}

function DateTimeFormatSelect({ field }: Props) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLLIElement>(null);

  return (
    <>
      <MenuItem ref={ref} onClick={() => setOpen(true)} className={'text-xs font-medium'}>
        <div className={'flex-1'}>
          {t('grid.field.dateFormat')} & {t('grid.field.timeFormat')}
        </div>
        <MoreSvg className={`transform text-base ${open ? '' : 'rotate-90'}`} />
      </MenuItem>
      <Menu
        anchorOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        open={open}
        anchorEl={ref.current}
        onClose={() => setOpen(false)}
        MenuListProps={{
          className: 'px-2',
        }}
      >
        <DateTimeFormat showLabel={false} field={field} />
      </Menu>
    </>
  );
}

export default DateTimeFormatSelect;
