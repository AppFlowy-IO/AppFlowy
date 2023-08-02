import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { TextAction } from '$app/interfaces/document';
import ColorPicker from '$app/components/document/TextActionMenu/menu/ColorPicker';
import { FormatColorText } from '@mui/icons-material';

function TextColorPicker() {
  const { t } = useTranslation();

  const getColorIcon = useCallback((color: string) => {
    return (
      <div className={'rounded border border-line-divider p-0.5'}>
        <FormatColorText style={{ color }} />
      </div>
    );
  }, []);

  const colors = useMemo(
    () => [
      {
        name: t('colors.default'),
        key: 'default',
        color: 'var(--text-title)',
      },
      {
        name: t('colors.custom'),
        key: 'custom',
        color: 'var(--text-title)',
      },
      {
        key: 'gray',
        name: t('colors.gray'),
        color: '#546e7a',
      },
      {
        key: 'brown',
        name: t('colors.brown'),
        color: '#795548',
      },
      {
        key: 'orange',
        name: t('colors.orange'),
        color: '#ff5722',
      },
      {
        key: 'yellow',
        name: t('colors.yellow'),
        color: '#ffff00',
      },
      {
        key: 'green',
        name: t('colors.green'),
        color: '#4caf50',
      },
      {
        key: 'blue',
        name: t('colors.blue'),
        color: '#0d47a1',
      },
      {
        key: 'purple',
        name: t('colors.purple'),
        color: '#9c27b0',
      },
      {
        key: 'pink',
        name: t('colors.pink'),
        color: '#d81b60',
      },
      {
        key: 'red',
        name: t('colors.red'),
        color: '#b71c1c',
      },
    ],
    [t]
  );

  return (
    <ColorPicker
      icon={
        <FormatColorText
          sx={{
            width: 18,
            height: 18,
          }}
        />
      }
      getColorIcon={getColorIcon}
      colors={colors}
      format={TextAction.TextColor}
      label={t('toolbar.color')}
    />
  );
}

export default TextColorPicker;
