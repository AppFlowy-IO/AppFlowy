import { notify } from '@/components/_shared/notify';
import ActionButton from '@/components/editor/components/toolbar/selection-toolbar/actions/ActionButton';
import { CodeNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';

function CodeToolbar ({ node }: {
  node: CodeNode
}) {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const onCopy = async () => {
    const at = ReactEditor.findPath(editor, node);
    const text = editor.string(at);

    await copyTextToClipboard(text);
    notify.success(t('publish.copy.codeBlock'));
  };

  return (
    <div className={'absolute z-10 top-1 right-1'}>
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

export default CodeToolbar;