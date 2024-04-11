import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { ReactComponent as BulletedListSvg } from '$app/assets/list.svg';

export function BulletedList() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isBlockActive(editor, EditorNodeType.BulletedListBlock);

  const onClick = useCallback(() => {
    CustomEditor.turnToBlock(editor, {
      type: EditorNodeType.BulletedListBlock,
    });
  }, [editor]);

  return (
    <ActionButton active={isActivated} onClick={onClick} tooltip={t('document.plugins.bulletedList')}>
      <BulletedListSvg />
    </ActionButton>
  );
}

export default BulletedList;
