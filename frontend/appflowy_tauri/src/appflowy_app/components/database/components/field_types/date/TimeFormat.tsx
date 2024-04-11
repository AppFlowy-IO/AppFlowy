import React, { useCallback, useMemo, useRef, useState } from 'react';
import { TimeFormatPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import { Menu, MenuItem } from '@mui/material';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { ReactComponent as SelectCheckSvg } from '$app/assets/select-check.svg';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

interface Props {
  value: TimeFormatPB;
  onChange: (value: TimeFormatPB) => void;
}
function TimeFormat({ value, onChange }: Props) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLLIElement>(null);

  const renderOptionContent = useCallback(
    (option: TimeFormatPB, title: string) => {
      return (
        <div className={'flex w-full items-center justify-between gap-2'}>
          <div className={'flex-1'}>{title}</div>
          {value === option && <SelectCheckSvg className={'text-content-blue-400'} />}
        </div>
      );
    },
    [value]
  );

  const options: KeyboardNavigationOption<TimeFormatPB>[] = useMemo(() => {
    return [
      {
        key: TimeFormatPB.TwelveHour,
        content: renderOptionContent(TimeFormatPB.TwelveHour, t('grid.field.timeFormatTwelveHour')),
      },
      {
        key: TimeFormatPB.TwentyFourHour,
        content: renderOptionContent(TimeFormatPB.TwentyFourHour, t('grid.field.timeFormatTwentyFourHour')),
      },
    ];
  }, [renderOptionContent, t]);

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

export default TimeFormat;
