import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as CodeSvg } from '$app/assets/inline-code.svg';

export function InlineCode() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isMarkActive(editor, 'code');

  const onClick = useCallback(() => {
    CustomEditor.toggleMark(editor, {
      key: 'code',
      value: true,
    });
  }, [editor]);

  return (
    <ActionButton onClick={onClick} active={isActivated} tooltip={t('editor.embedCode')}>
      <CodeSvg />
    </ActionButton>
  );
}

export default InlineCode;
