import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { ReactComponent as QuoteSvg } from '$app/assets/quote.svg';

export function Quote() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isBlockActive(editor, EditorNodeType.QuoteBlock);

  const onClick = useCallback(() => {
    let type = EditorNodeType.QuoteBlock;

    if (isActivated) {
      type = EditorNodeType.Paragraph;
    }

    CustomEditor.turnToBlock(editor, {
      type,
    });
  }, [editor, isActivated]);

  return (
    <ActionButton active={isActivated} onClick={onClick} tooltip={t('editor.quote')}>
      <QuoteSvg />
    </ActionButton>
  );
}

export default Quote;
