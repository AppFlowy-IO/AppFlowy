import React, { useCallback, useMemo } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as CodeSvg } from '$app/assets/inline-code.svg';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { createHotKeyLabel, HOT_KEY_NAME } from '$app/utils/hotkeys';

export function InlineCode() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Code);
  const modifier = useMemo(() => createHotKeyLabel(HOT_KEY_NAME.CODE), []);

  const onClick = useCallback(() => {
    CustomEditor.toggleMark(editor, {
      key: EditorMarkFormat.Code,
      value: true,
    });
  }, [editor]);

  return (
    <ActionButton
      onClick={onClick}
      active={isActivated}
      tooltip={
        <>
          <div>{t('editor.embedCode')}</div>
          <div className={'text-xs text-text-caption'}>{modifier}</div>
        </>
      }
    >
      <CodeSvg />
    </ActionButton>
  );
}

export default InlineCode;
