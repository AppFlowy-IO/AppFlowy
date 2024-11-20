import { notify } from '@/components/_shared/notify';
import ActionButton from '@/components/editor/components/toolbar/selection-toolbar/actions/ActionButton';
import { MathEquationNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';

function MathEquationToolbar ({
  node,
}: {
  node: MathEquationNode
}) {
  const { t } = useTranslation();
  const formula = node.data.formula || '';

  const onCopy = async () => {
    await copyTextToClipboard(formula);
    notify.success(t('publish.copy.mathBlock'));
  };

  return (
    <div className={'absolute z-10 top-2 right-1'}>
      <div className={'flex space-x-1 rounded-[8px] p-1 bg-fill-toolbar shadow border border-line-divider '}>
        <ActionButton
          onClick={onCopy}
          tooltip={t('editor.copy')}
        >
          <CopyIcon />
        </ActionButton>
      </div>
    </div>
  );
}

export default MathEquationToolbar;