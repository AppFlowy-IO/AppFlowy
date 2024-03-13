import React, { useCallback, useEffect, useMemo } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as ItalicSvg } from '$app/assets/italic.svg';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { createHotkey, createHotKeyLabel, HOT_KEY_NAME } from '$app/utils/hotkeys';

export function Italic() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Italic);
  const modifier = useMemo(() => createHotKeyLabel(HOT_KEY_NAME.ITALIC), []);

  const onClick = useCallback(() => {
    CustomEditor.toggleMark(editor, {
      key: EditorMarkFormat.Italic,
      value: true,
    });
  }, [editor]);

  useEffect(() => {
    const editorDom = ReactEditor.toDOMNode(editor, editor);
    const handleShortcut = (e: KeyboardEvent) => {
      if (createHotkey(HOT_KEY_NAME.ITALIC)(e)) {
        e.preventDefault();
        e.stopPropagation();
        CustomEditor.toggleMark(editor, {
          key: EditorMarkFormat.Italic,
          value: true,
        });
        return;
      }
    };

    editorDom.addEventListener('keydown', handleShortcut);
    return () => {
      editorDom.removeEventListener('keydown', handleShortcut);
    };
  }, [editor]);
  return (
    <ActionButton
      onClick={onClick}
      active={isActivated}
      tooltip={
        <>
          <div>{t('toolbar.italic')}</div>
          <div className={'text-xs text-text-caption'}>{modifier}</div>
        </>
      }
    >
      <ItalicSvg />
    </ActionButton>
  );
}

export default Italic;
