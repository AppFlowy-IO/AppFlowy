import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { ColorPicker } from '@/components/_shared/color-picker';
import {
  SelectionToolbarPopoverProvider,
  useSelectionToolbarPopoverContext,
} from '@/components/editor/components/toolbar/selection-toolbar/SelectionToolbarPopoverContext';
import React, { useCallback } from 'react';
import ActionButton from './ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as ColorSvg } from '@/assets/color_theme.svg';

function ColorButton () {
  const { t } = useTranslation();
  const editor = useSlateStatic() as YjsEditor;
  const { openPopover } = useSelectionToolbarPopoverContext();
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.BgColor) || CustomEditor.isMarkActive(editor, EditorMarkFormat.FontColor);

  const onClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    openPopover();
  }, [openPopover]);

  return (
    <ActionButton
      onClick={onClick}
      active={isActivated}
      tooltip={t('editor.color')}
    >
      <ColorSvg />
    </ActionButton>
  );
}

function ColorPickerContent () {
  const editor = useSlateStatic() as YjsEditor;
  const { closePopover } = useSelectionToolbarPopoverContext();

  const handlePickedColor = useCallback((format: EditorMarkFormat, color: string) => {
    if (color) {
      CustomEditor.addMark(editor, {
        key: format,
        value: color,
      });
    } else {
      CustomEditor.removeMark(editor, format);
    }
  }, [editor]);

  return (
    <ColorPicker
      disableFocus={true}
      onEscape={closePopover}
      onChange={handlePickedColor}
    />
  );
}

function Color () {
  return (
    <SelectionToolbarPopoverProvider popoverContent={<ColorPickerContent />}>
      <ColorButton />
    </SelectionToolbarPopoverProvider>
  );
}

export default Color;