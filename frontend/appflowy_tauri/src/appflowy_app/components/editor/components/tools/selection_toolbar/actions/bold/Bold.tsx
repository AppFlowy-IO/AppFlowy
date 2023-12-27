import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as BoldSvg } from '$app/assets/bold.svg';

export function Bold() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isMarkActive(editor, 'bold');

  const onClick = useCallback(() => {
    CustomEditor.toggleMark(editor, {
      key: 'bold',
      value: true,
    });
  }, [editor]);

  return (
    <ActionButton onClick={onClick} active={isActivated} tooltip={t('editor.bold')}>
      <BoldSvg />
    </ActionButton>
  );
}

export default Bold;
