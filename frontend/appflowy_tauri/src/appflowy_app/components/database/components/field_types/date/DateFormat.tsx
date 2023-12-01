import React, { useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { MenuItem, Menu } from '@mui/material';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';

import { DateFormatPB } from '@/services/backend';

interface Props {
  value: DateFormatPB;
  onChange: (value: DateFormatPB) => void;
}

function DateFormat({ value, onChange }: Props) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLLIElement>(null);
  const dateFormatMap = useMemo(
    () => ({
      [DateFormatPB.Friendly]: t('grid.field.dateFormatFriendly'),
      [DateFormatPB.ISO]: t('grid.field.dateFormatISO'),
      [DateFormatPB.US]: t('grid.field.dateFormatUS'),
      [DateFormatPB.Local]: t('grid.field.dateFormatLocal'),
      [DateFormatPB.DayMonthYear]: t('grid.field.dateFormatDayMonthYear'),
    }),
    [t]
  );

  const handleClick = (option: DateFormatPB) => {
    onChange(option);
    setOpen(false);
  };

  return (
    <>
      <MenuItem
        className={'mx-0 flex w-full justify-between text-xs font-medium'}
        ref={ref}
        onClick={() => setOpen(true)}
      >
        {t('grid.field.dateFormat')}
        <MoreSvg className={`transform text-base ${open ? '' : 'rotate-90'}`} />
      </MenuItem>
      <Menu
        anchorOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        open={open}
        anchorEl={ref.current}
        onClose={() => setOpen(false)}
      >
        {Object.keys(dateFormatMap).map((option) => {
          const optionValue = Number(option) as DateFormatPB;

          return (
            <MenuItem
              className={'min-w-[180px] justify-between'}
              key={optionValue}
              onClick={() => handleClick(optionValue)}
            >
              {dateFormatMap[optionValue]}
              {value === optionValue && <SelectCheckSvg />}
            </MenuItem>
          );
        })}
      </Menu>
    </>
  );
}

export default DateFormat;
