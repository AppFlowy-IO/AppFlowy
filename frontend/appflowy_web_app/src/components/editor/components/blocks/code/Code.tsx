import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { useCodeBlock } from '@/components/editor/components/blocks/code/Code.hooks';
import { CodeNode, EditorElementProps } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import React, { forwardRef, memo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlateStatic } from 'slate-react';
import LanguageSelect from './SelectLanguage';

export const CodeBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CodeNode>>(({ node, children, ...attributes }, ref) => {
    const { language, handleChangeLanguage } = useCodeBlock(node);
    const [showToolbar, setShowToolbar] = useState(false);
    const { t } = useTranslation();
    const editor = useSlateStatic();

    return (
      <div
        className={'relative w-full'}
        onMouseEnter={() => {
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
      >
        <div
          contentEditable={false}
          className={'absolute mt-2  flex h-20 w-full select-none items-center px-6'}
        >
          <LanguageSelect
            readOnly
            language={language}
            onChangeLanguage={handleChangeLanguage}
          />
        </div>
        <div {...attributes} ref={ref}
             className={`${attributes.className ?? ''} flex w-full bg-bg-body py-2`}
        >
          <pre
            spellCheck={false}
            className={`flex w-full overflow-hidden rounded-[8px] border border-line-divider bg-fill-list-active p-5 pt-20`}
          >
            <code>{children}</code>
          </pre>
        </div>
        {showToolbar && (
          <RightTopActionsToolbar
            style={{
              top: '16px',
            }}
            onCopy={async () => {
              try {
                const at = ReactEditor.findPath(editor, node);
                const text = editor.string(at);

                await copyTextToClipboard(text);
                notify.success(t('publish.copy.codeBlock'));
              } catch (_) {
                // do nothing
              }
            }}
          />
        )}
      </div>
    );
  }),
  (prevProps, nextProps) => JSON.stringify(prevProps.node) === JSON.stringify(nextProps.node),
);
export default CodeBlock;
