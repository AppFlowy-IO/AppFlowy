import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import Functions from '@mui/icons-material/Functions';
import { useEditorInlineBlockState } from '$app/components/editor/stores';

export function Formula() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivatedMention = CustomEditor.isMentionActive(editor);

  const formulaMatch = CustomEditor.formulaActiveNode(editor);
  const isActivated = !isActivatedMention && CustomEditor.isFormulaActive(editor);

  const { setRange, openPopover } = useEditorInlineBlockState('formula');
  const onClick = useCallback(() => {
    let selection = editor.selection;

    if (!selection) return;
    if (formulaMatch) {
      selection = editor.range(formulaMatch[1]);
      editor.select(selection);
    } else {
      CustomEditor.toggleFormula(editor);
    }

    requestAnimationFrame(() => {
      const selection = editor.selection;

      if (!selection) return;

      setRange(selection);
      openPopover();
    });
  }, [editor, formulaMatch, setRange, openPopover]);

  return (
    <ActionButton
      disabled={isActivatedMention}
      onClick={onClick}
      active={isActivated}
      tooltip={t('document.plugins.createInlineMathEquation')}
    >
      <Functions className={`w-[14px]`} />
    </ActionButton>
  );
}

export default Formula;
