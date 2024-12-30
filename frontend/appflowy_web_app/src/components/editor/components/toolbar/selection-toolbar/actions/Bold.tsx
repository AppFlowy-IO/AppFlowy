import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import ActionButton from '@/components/editor/components/toolbar/selection-toolbar/actions/ActionButton';
import { createHotKeyLabel, HOT_KEY_NAME } from '@/utils/hotkeys';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as BoldSvg } from '@/assets/bold.svg';

export function Bold () {
  const { t } = useTranslation();
  const editor = useSlateStatic() as YjsEditor;
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
