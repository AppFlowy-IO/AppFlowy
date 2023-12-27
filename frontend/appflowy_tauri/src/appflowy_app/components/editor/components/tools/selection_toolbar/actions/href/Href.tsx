import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as LinkSvg } from '$app/assets/link.svg';
import { Editor } from 'slate';
import { EditorMarkFormat } from '$app/application/document/document.types';

export function Href() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Href);

  const onClick = useCallback(() => {
    if (!editor.selection) return;
    const text = Editor.string(editor, editor.selection);

    CustomEditor.toggleMark(editor, {
      key: EditorMarkFormat.Href,
      value: text,
    });
  }, [editor]);

  return (
    <ActionButton onClick={onClick} active={isActivated} tooltip={t('editor.link')}>
      <LinkSvg />
    </ActionButton>
  );
}

export default Href;
