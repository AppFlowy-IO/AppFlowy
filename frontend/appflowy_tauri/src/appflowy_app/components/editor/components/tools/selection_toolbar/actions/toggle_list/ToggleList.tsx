import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { EditorNodeType } from '$app/application/document/document.types';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { ReactComponent as ToggleListSvg } from '$app/assets/show-menu.svg';

export function ToggleList() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isBlockActive(editor, EditorNodeType.ToggleListBlock);

  const onClick = useCallback(() => {
    CustomEditor.turnToBlock(editor, {
      type: EditorNodeType.ToggleListBlock,
    });
  }, [editor]);

  return (
    <ActionButton active={isActivated} onClick={onClick} tooltip={t('document.plugins.toggleList')}>
      <ToggleListSvg />
    </ActionButton>
  );
}

export default ToggleList;
