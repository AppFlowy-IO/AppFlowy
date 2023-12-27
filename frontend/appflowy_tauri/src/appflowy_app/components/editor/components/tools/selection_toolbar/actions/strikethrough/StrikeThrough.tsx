import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as StrikeThroughSvg } from '$app/assets/strikethrough.svg';

export function StrikeThrough() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isMarkActive(editor, 'strikethrough');

  const onClick = useCallback(() => {
    CustomEditor.toggleMark(editor, {
      key: 'strikethrough',
      value: true,
    });
  }, [editor]);

  return (
    <ActionButton onClick={onClick} active={isActivated} tooltip={t('editor.strikethrough')}>
      <StrikeThroughSvg />
    </ActionButton>
  );
}

export default StrikeThrough;
