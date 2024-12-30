import { EditorMarkFormat } from '@/application/slate-yjs/types';
import KeyboardNavigation from '@/components/_shared/keyboard_navigation/KeyboardNavigation';
import { ColorEnum, renderColor } from '@/utils/color';
import React, { useCallback, useRef, useMemo } from 'react';
import Typography from '@mui/material/Typography';

import { useTranslation } from 'react-i18next';
import { TitleOutlined } from '@mui/icons-material';

export interface ColorPickerProps {
  onChange?: (format: EditorMarkFormat.FontColor | EditorMarkFormat.BgColor, color: string) => void;
  onEscape?: () => void;
  disableFocus?: boolean;
}

export function ColorPicker ({ onEscape, onChange, disableFocus }: ColorPickerProps) {
  const { t } = useTranslation();

  const ref = useRef<HTMLDivElement>(null);

  const handleColorChange = useCallback(
    (key: string) => {
      const [format, , color = ''] = key.split('-');
      const formatKey = format === 'font' ? EditorMarkFormat.FontColor : EditorMarkFormat.BgColor;

      onChange?.(formatKey, color);
    },
    [onChange],
  );

  const renderColorItem = useCallback(
    (name: string, color: string, backgroundColor?: string) => {
      return (
        <div
          key={name}
          onClick={() => {
            handleColorChange(backgroundColor ? backgroundColor : color);
          }}
          className={'flex w-full cursor-pointer items-center justify-center gap-2'}
        >
          <div
            style={{
              backgroundColor: backgroundColor ? renderColor(backgroundColor) : 'transparent',
              color: color === '' ? 'var(--text-title)' : renderColor(color),
            }}
            className={'flex h-5 w-5 items-center justify-center rounded border border-line-divider'}
          >
            <TitleOutlined className={'h-4 w-4'} />
          </div>
          <div className={'flex-1 text-xs text-text-title'}>{name}</div>
        </div>
      );
    },
    [handleColorChange],
  );

  const colors = useMemo(() => {
    return [
      {
        key: 'font_color',
        content: (
          <Typography
            className={'px-3 pb-1 pt-3 text-text-caption'}
            variant="subtitle2"
          >
            {t('editor.textColor')}
          </Typography>
        ),
        children: [
          {
            key: 'font-default',
            content: renderColorItem(t('editor.fontColorDefault'), ''),
          },
          {
            key: `font-gray-rgb(120, 119, 116)`,
            content: renderColorItem(t('editor.fontColorGray'), 'rgb(120, 119, 116)'),
          },
          {
            key: 'font-brown-rgb(159, 107, 83)',
            content: renderColorItem(t('editor.fontColorBrown'), 'rgb(159, 107, 83)'),
          },
          {
            key: 'font-orange-rgb(217, 115, 13)',
            content: renderColorItem(t('editor.fontColorOrange'), 'rgb(217, 115, 13)'),
          },
          {
            key: 'font-yellow-rgb(203, 145, 47)',
            content: renderColorItem(t('editor.fontColorYellow'), 'rgb(203, 145, 47)'),
          },
          {
            key: 'font-green-rgb(68, 131, 97)',
            content: renderColorItem(t('editor.fontColorGreen'), 'rgb(68, 131, 97)'),
          },
          {
            key: 'font-blue-rgb(51, 126, 169)',
            content: renderColorItem(t('editor.fontColorBlue'), 'rgb(51, 126, 169)'),
          },
          {
            key: 'font-purple-rgb(144, 101, 176)',
            content: renderColorItem(t('editor.fontColorPurple'), 'rgb(144, 101, 176)'),
          },
          {
            key: 'font-pink-rgb(193, 76, 138)',
            content: renderColorItem(t('editor.fontColorPink'), 'rgb(193, 76, 138)'),
          },
          {
            key: 'font-red-rgb(212, 76, 71)',
            content: renderColorItem(t('editor.fontColorRed'), 'rgb(212, 76, 71)'),
          },
        ],
      },
      {
        key: 'bg_color',
        content: (
          <Typography
            className={'px-3 pb-1 pt-3 text-text-caption'}
            variant="subtitle2"
          >
            {t('editor.backgroundColor')}
          </Typography>
        ),
        children: [
          {
            key: 'bg-default',
            content: renderColorItem(t('editor.backgroundColorDefault'), '', ''),
          },
          {
            key: `bg-lime-${ColorEnum.Lime}`,
            content: renderColorItem(t('editor.backgroundColorLime'), '', ColorEnum.Lime),
          },
          {
            key: `bg-aqua-${ColorEnum.Aqua}`,
            content: renderColorItem(t('editor.backgroundColorAqua'), '', ColorEnum.Aqua),
          },
          {
            key: `bg-orange-${ColorEnum.Orange}`,
            content: renderColorItem(t('editor.backgroundColorOrange'), '', ColorEnum.Orange),
          },
          {
            key: `bg-yellow-${ColorEnum.Yellow}`,
            content: renderColorItem(t('editor.backgroundColorYellow'), '', ColorEnum.Yellow),
          },
          {
            key: `bg-green-${ColorEnum.Green}`,
            content: renderColorItem(t('editor.backgroundColorGreen'), '', ColorEnum.Green),
          },
          {
            key: `bg-blue-${ColorEnum.Blue}`,
            content: renderColorItem(t('editor.backgroundColorBlue'), '', ColorEnum.Blue),
          },
          {
            key: `bg-purple-${ColorEnum.Purple}`,
            content: renderColorItem(t('editor.backgroundColorPurple'), '', ColorEnum.Purple),
          },
          {
            key: `bg-pink-${ColorEnum.Pink}`,
            content: renderColorItem(t('editor.backgroundColorPink'), '', ColorEnum.Pink),
          },
          {
            key: `bg-red-${ColorEnum.LightPink}`,
            content: renderColorItem(t('editor.backgroundColorRed'), '', ColorEnum.LightPink),
          },
        ],
      },
    ];
  }, [renderColorItem, t]);

  return (
    <div
      ref={ref}
      className={'flex h-full max-h-[420px] appflowy-scroller w-full flex-col overflow-y-auto'}
    >
      <KeyboardNavigation
        disableFocus={disableFocus}
        onPressLeft={onEscape}
        scrollRef={ref}
        options={colors}
        onConfirm={handleColorChange}
        onEscape={onEscape}
      />
    </div>
  );
}
