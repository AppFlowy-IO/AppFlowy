import React, { useCallback, useMemo } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as BoldSvg } from '$app/assets/bold.svg';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { createHotKeyLabel, HOT_KEY_NAME } from '$app/utils/hotkeys';

export function Bold() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Bold);

  const modifier = useMemo(() => createHotKeyLabel(HOT_KEY_NAME.BOLD), []);
  const onClick = useCallback(() => {
    CustomEditor.toggleMark(editor, {
      key: EditorMarkFormat.Bold,
      value: true,
    });
  }, [editor]);

  return (
    <ActionButton
      onClick={onClick}
      active={isActivated}
      tooltip={
        <>
          <div>{t('toolbar.bold')}</div>
          <div className={'text-xs text-text-caption'}>{modifier}</div>
        </>
      }
    >
      <BoldSvg />
    </ActionButton>
  );
}

export default Bold;
