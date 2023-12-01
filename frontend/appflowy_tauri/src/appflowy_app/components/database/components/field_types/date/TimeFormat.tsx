import React, { useMemo, useRef, useState } from 'react';
import { TimeFormatPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import { Menu, MenuItem } from '@mui/material';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';

interface Props {
  value: TimeFormatPB;
  onChange: (value: TimeFormatPB) => void;
}
function TimeFormat({ value, onChange }: Props) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLLIElement>(null);
  const timeFormatMap = useMemo(
    () => ({
      [TimeFormatPB.TwelveHour]: t('grid.field.timeFormatTwelveHour'),
      [TimeFormatPB.TwentyFourHour]: t('grid.field.timeFormatTwentyFourHour'),
    }),
    [t]
  );

  const handleClick = (option: TimeFormatPB) => {
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
        {t('grid.field.timeFormat')}
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
        {Object.keys(timeFormatMap).map((option) => {
          const optionValue = Number(option) as TimeFormatPB;

          return (
            <MenuItem
              className={'min-w-[120px] justify-between'}
              key={optionValue}
              onClick={() => handleClick(optionValue)}
            >
              {timeFormatMap[optionValue]}
              {value === optionValue && <SelectCheckSvg />}
            </MenuItem>
          );
        })}
      </Menu>
    </>
  );
}

export default TimeFormat;
