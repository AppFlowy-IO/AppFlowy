import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { ReactComponent as NumberedListSvg } from '$app/assets/numbers.svg';

export function NumberedList() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isBlockActive(editor, EditorNodeType.NumberedListBlock);

  const onClick = useCallback(() => {
    let type = EditorNodeType.NumberedListBlock;

    if (isActivated) {
      type = EditorNodeType.Paragraph;
    }

    CustomEditor.turnToBlock(editor, {
      type,
    });
  }, [editor, isActivated]);

  return (
    <ActionButton active={isActivated} onClick={onClick} tooltip={t('document.plugins.numberedList')}>
      <NumberedListSvg />
    </ActionButton>
  );
}

export default NumberedList;
