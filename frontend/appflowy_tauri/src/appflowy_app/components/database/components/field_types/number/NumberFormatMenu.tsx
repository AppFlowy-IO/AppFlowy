import React, { useCallback, useMemo, useRef } from 'react';
import { NumberFormatPB } from '@/services/backend';
import { Menu, MenuProps } from '@mui/material';
import { formats, formatText } from '$app/components/database/components/field_types/number/const';
import { ReactComponent as SelectCheckSvg } from '$app/assets/select-check.svg';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

function NumberFormatMenu({
  value,
  onChangeFormat,
  ...props
}: MenuProps & {
  value: NumberFormatPB;
  onChangeFormat: (value: NumberFormatPB) => void;
}) {
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const onConfirm = useCallback(
    (format: NumberFormatPB) => {
      onChangeFormat(format);
      props.onClose?.({}, 'backdropClick');
    },
    [onChangeFormat, props]
  );

  const renderContent = useCallback(
    (format: NumberFormatPB) => {
      return (
        <>
          <span className={'flex-1'}>{formatText(format)}</span>
          {value === format && <SelectCheckSvg className={'text-content-blue-400'} />}
        </>
      );
    },
    [value]
  );

  const options: KeyboardNavigationOption<NumberFormatPB>[] = useMemo(
    () =>
      formats.map((format) => ({
        key: format.value as NumberFormatPB,
        content: renderContent(format.value as NumberFormatPB),
      })),
    [renderContent]
  );

  return (
    <Menu {...props}>
      <div ref={scrollRef} className={'max-h-[360px] overflow-y-auto overflow-x-hidden'}>
        <KeyboardNavigation
          defaultFocusedKey={value}
          scrollRef={scrollRef}
          options={options}
          onConfirm={onConfirm}
          disableFocus={true}
          onEscape={() => props.onClose?.({}, 'escapeKeyDown')}
        />
      </div>
    </Menu>
  );
}

export default NumberFormatMenu;
