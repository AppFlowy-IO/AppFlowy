import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import Functions from '@mui/icons-material/Functions';

export function Formula() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivated = CustomEditor.isFormulaActive(editor);

  const onClick = useCallback(() => {
    CustomEditor.toggleFormula(editor);
  }, [editor]);

  return (
    <ActionButton onClick={onClick} active={isActivated} tooltip={t('document.plugins.createInlineMathEquation')}>
      <Functions className={'w-[14px]'} />
    </ActionButton>
  );
}

export default Formula;
