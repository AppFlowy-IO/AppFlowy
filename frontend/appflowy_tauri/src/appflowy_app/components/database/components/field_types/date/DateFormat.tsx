import React, { useCallback, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { MenuItem, Menu } from '@mui/material';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { ReactComponent as SelectCheckSvg } from '$app/assets/select-check.svg';

import { DateFormatPB } from '@/services/backend';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

interface Props {
  value: DateFormatPB;
  onChange: (value: DateFormatPB) => void;
}

function DateFormat({ value, onChange }: Props) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLLIElement>(null);

  const renderOptionContent = useCallback(
    (option: DateFormatPB, title: string) => {
      return (
        <div className={'flex w-full items-center justify-between gap-2'}>
          <div className={'flex-1'}>{title}</div>
          {value === option && <SelectCheckSvg />}
        </div>
      );
    },
    [value]
  );

  const options: KeyboardNavigationOption<DateFormatPB>[] = useMemo(() => {
    return [
      {
        key: DateFormatPB.Friendly,
        content: renderOptionContent(DateFormatPB.Friendly, t('grid.field.dateFormatFriendly')),
      },
      {
        key: DateFormatPB.ISO,
        content: renderOptionContent(DateFormatPB.ISO, t('grid.field.dateFormatISO')),
      },
      {
        key: DateFormatPB.US,
        content: renderOptionContent(DateFormatPB.US, t('grid.field.dateFormatUS')),
      },
      {
        key: DateFormatPB.Local,
        content: renderOptionContent(DateFormatPB.Local, t('grid.field.dateFormatLocal')),
      },
      {
        key: DateFormatPB.DayMonthYear,
        content: renderOptionContent(DateFormatPB.DayMonthYear, t('grid.field.dateFormatDayMonthYear')),
      },
    ];
  }, [renderOptionContent, t]);

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
        <KeyboardNavigation
          onEscape={() => {
            setOpen(false);
          }}
          disableFocus={true}
          options={options}
          onConfirm={handleClick}
        />
      </Menu>
    </>
  );
}

export default DateFormat;
