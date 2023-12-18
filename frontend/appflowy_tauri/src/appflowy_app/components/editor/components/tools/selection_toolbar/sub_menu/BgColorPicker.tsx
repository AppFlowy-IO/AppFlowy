import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  ColorPicker,
  ColorPickerProps,
} from '$app/components/editor/components/tools/selection_toolbar/sub_menu/ColorPicker';

export function BgColorPicker(props: ColorPickerProps) {
  const { t } = useTranslation();

  return <ColorPicker {...props} label={t('editor.backgroundColor')} />;
}
