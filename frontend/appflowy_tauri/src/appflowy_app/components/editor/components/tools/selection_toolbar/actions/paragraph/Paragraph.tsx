import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { getBlock } from '$app/components/editor/plugins/utils';
import { CustomEditor } from '$app/components/editor/command';
import { EditorNodeType } from '$app/application/document/document.types';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as ParagraphSvg } from '$app/assets/text.svg';

export function Paragraph() {
  const { t } = useTranslation();
  const editor = useSlateStatic();

  const onClick = useCallback(() => {
    const node = getBlock(editor);

    if (!node) return;

    CustomEditor.turnToBlock(editor, {
      type: EditorNodeType.Paragraph,
    });
  }, [editor]);

  const isActive = CustomEditor.isBlockActive(editor, EditorNodeType.Paragraph);

  return (
    <ActionButton active={isActive} onClick={onClick} tooltip={t('editor.text')}>
      <ParagraphSvg />
    </ActionButton>
  );
}

export default Paragraph;
