import React, { useCallback, useMemo } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as LinkSvg } from '$app/assets/link.svg';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { useDecorateDispatch } from '$app/components/editor/stores';
import { getModifier } from '$app/utils/hotkeys';

export function Href() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivatedInline = CustomEditor.isInlineActive(editor);
  const isActivated = !isActivatedInline && CustomEditor.isMarkActive(editor, EditorMarkFormat.Href);

  const { add: addDecorate } = useDecorateDispatch();
  const onClick = useCallback(() => {
    if (!editor.selection) return;
    addDecorate({
      range: editor.selection,
      class_name: 'bg-content-blue-100 rounded',
      type: 'link',
    });
  }, [addDecorate, editor]);

  const tooltip = useMemo(() => {
    const modifier = getModifier();

    return (
      <>
        <div>{t('editor.link')}</div>
        <div className={'text-xs text-text-caption'}>{`${modifier} + K`}</div>
      </>
    );
  }, [t]);

  return (
    <>
      <ActionButton disabled={isActivatedInline} onClick={onClick} active={isActivated} tooltip={tooltip}>
        <LinkSvg />
      </ActionButton>
    </>
  );
}

export default Href;
