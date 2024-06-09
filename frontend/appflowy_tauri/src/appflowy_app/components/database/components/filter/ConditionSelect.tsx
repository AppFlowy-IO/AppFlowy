import React, { useCallback, useMemo, useState } from 'react';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import Popover from '@mui/material/Popover';

function ConditionSelect({
  conditions,
  value,
  onChange,
}: {
  conditions: {
    value: number;
    text: string;
  }[];
  value: number;
  onChange: (condition: number) => void;
}) {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const options: KeyboardNavigationOption<number>[] = useMemo(() => {
    return conditions.map((condition) => {
      return {
        key: condition.value,
        content: condition.text,
      };
    });
  }, [conditions]);

  const handleClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const onConfirm = useCallback(
    (key: number) => {
      onChange(key);
    },
    [onChange]
  );

  const valueText = useMemo(() => {
    return conditions.find((condition) => condition.value === value)?.text;
  }, [conditions, value]);

  const open = Boolean(anchorEl);

  return (
    <div>
      <div
        onClick={(e) => {
          setAnchorEl(e.currentTarget);
        }}
        className={'flex cursor-pointer select-none items-center gap-2 py-2 text-xs'}
      >
        <div className={'flex-1'}>{valueText}</div>
        <MoreSvg className={`h-4 w-4 transform ${open ? 'rotate-90' : ''}`} />
      </div>
      <Popover
        open={open}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'center',
        }}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'center',
        }}
        anchorEl={anchorEl}
        onClose={handleClose}
        keepMounted={false}
      >
        <KeyboardNavigation defaultFocusedKey={value} options={options} onConfirm={onConfirm} onEscape={handleClose} />
      </Popover>
    </div>
  );
}

export default ConditionSelect;
