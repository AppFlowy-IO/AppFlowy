import React, { useCallback, useEffect, useRef, useState } from 'react';
import { List } from '@mui/material';
import MenuItem from '@mui/material/MenuItem';
import { useBindArrowKey } from '$app/components/document/_shared/useBindArrowKey';
import Popover from '@mui/material/Popover';
import Tooltip from '@mui/material/Tooltip';
import { useAppDispatch } from '$app/stores/store';
import { formatThunk, getFormatValuesThunk } from '$app_reducers/document/async-actions/format';
import { TextAction } from '$app/interfaces/document';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import CustomColorPicker from '$app/components/document/TextActionMenu/menu/CustomColorPicker';

export interface ColorItem {
  name: string;
  key: string;
  color: string;
}
function ColorPicker({
  label,
  format,
  colors,
  icon,
  getColorIcon,
}: {
  format: TextAction;
  label: string;
  colors: ColorItem[];
  icon: React.ReactNode;
  getColorIcon: (color: string) => React.ReactNode;
}) {
  const { controller, docId } = useSubscribeDocument();
  const ref = useRef<HTMLDivElement>(null);
  const [anchorPosition, setAnchorPosition] = useState<
    | {
        left: number;
        top: number;
      }
    | undefined
  >(undefined);
  const open = Boolean(anchorPosition);
  const dispatch = useAppDispatch();
  const [customPickerAnchorPosition, setCustomPickerAnchorPosition] = useState<
    | {
        left: number;
        top: number;
      }
    | undefined
  >(undefined);
  const customOpened = Boolean(customPickerAnchorPosition);
  const [selectOption, setSelectOption] = useState<string | null>(null);
  const [activeColor, setActiveColor] = useState<string | null>(null);

  const openCustomColorPicker = useCallback(() => {
    const target = document.querySelector('.color-item-custom') as Element;

    const rect = target.getBoundingClientRect();

    setCustomPickerAnchorPosition({
      left: rect.left + rect.width + 10,
      top: rect.top,
    });
  }, []);

  useEffect(() => {
    if (selectOption === 'custom') {
      openCustomColorPicker();
    } else {
      setCustomPickerAnchorPosition(undefined);
    }
  }, [selectOption, openCustomColorPicker]);

  const onOpen = useCallback(() => {
    const rect = ref.current?.getBoundingClientRect();

    if (!rect) return;
    setAnchorPosition({
      left: rect.left,
      top: rect.top + rect.height + 10,
    });
  }, []);

  const loadActiveColor = useCallback(async () => {
    const { payload: formatValues } = (await dispatch(getFormatValuesThunk({ format, docId }))) as {
      payload: Record<string, (boolean | string | undefined)[]>;
    };
    const multiLines = Object.keys(formatValues).length > 1;
    const firstKey = Object.keys(formatValues)[0];
    const firstValue = formatValues[firstKey].find((item) => item);

    setActiveColor(multiLines ? null : String(firstValue));
  }, [dispatch, docId, format]);

  useEffect(() => {
    void (async () => {
      await loadActiveColor();
    })();
  }, [loadActiveColor]);

  const formatColor = useCallback(
    async (color: string | null) => {
      await dispatch(formatThunk({ format, value: color, controller }));
      setAnchorPosition(undefined);
      await loadActiveColor();
    },
    [format, controller, dispatch, loadActiveColor]
  );

  const onClick = useCallback(async () => {
    if (selectOption === 'custom') {
      return;
    }

    if (selectOption === 'default') {
      await formatColor(null);
    } else {
      const item = colors.find((color) => color.key === selectOption);

      await formatColor(item?.color || null);
    }
  }, [selectOption, formatColor, colors]);

  useBindArrowKey({
    options: colors.map((item) => item.key),
    onChange: (key) => {
      setSelectOption(key);
    },
    selectOption,
    onEnter: () => onClick(),
  });

  return (
    <>
      <div
        ref={ref}
        className={'cursor-pointer px-1.5 hover:text-fill-hover'}
        onClick={onOpen}
        style={{
          color: activeColor || undefined,
        }}
      >
        <Tooltip placement={'top-start'} disableInteractive title={label}>
          <div>{icon}</div>
        </Tooltip>
      </div>
      <Popover
        onMouseDown={(e) => {
          e.stopPropagation();
        }}
        disableAutoFocus={true}
        disableRestoreFocus={true}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        open={open}
        anchorReference={'anchorPosition'}
        anchorPosition={anchorPosition}
        onClose={() => setAnchorPosition(undefined)}
      >
        <List>
          <div className={'w-[200px] px-4 py-2 uppercase text-text-caption'}>{label}</div>
          {colors.map((item) => (
            <MenuItem
              className={`color-item-${item.key}`}
              key={item.key}
              onMouseEnter={() => {
                setSelectOption(item.key);
              }}
              style={{
                padding: '4px',
              }}
              selected={selectOption === item.key}
              onClick={onClick}
            >
              <div className={'flex items-center'}>
                {getColorIcon(item.color)}
                <div className={'ml-2'}>{item.name}</div>
              </div>
              {item.key === 'custom' && (
                <CustomColorPicker
                  open={customOpened}
                  onChange={formatColor}
                  anchorPosition={customPickerAnchorPosition}
                  onClose={() => {
                    setCustomPickerAnchorPosition(undefined);
                  }}
                />
              )}
            </MenuItem>
          ))}
        </List>
      </Popover>
    </>
  );
}

export default ColorPicker;
