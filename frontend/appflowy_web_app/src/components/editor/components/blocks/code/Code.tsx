import { useCodeBlock } from '@/components/editor/components/blocks/code/Code.hooks';
import CodeToolbar from './CodeToolbar';
import { CodeNode, EditorElementProps } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useState } from 'react';
import { useReadOnly } from 'slate-react';
import LanguageSelect from './SelectLanguage';

export const CodeBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CodeNode>>(({ node, children, ...attributes }, ref) => {
    const { language, handleChangeLanguage } = useCodeBlock(node);
    const [showToolbar, setShowToolbar] = useState(false);

    const readOnly = useReadOnly();

    return (
      <div
        className={'relative w-full'}
        onMouseEnter={() => {
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
      >
        {showToolbar && <div
          contentEditable={false}
          className={'absolute flex h-12 w-full select-none items-center px-2'}
        >
          <LanguageSelect
            readOnly={readOnly}
            language={language}
            onChangeLanguage={handleChangeLanguage}
          />
        </div>}

        <div {...attributes} ref={ref}
             className={`${attributes.className ?? ''}  flex w-full`}
        >
          <pre
            spellCheck={false}
            className={`flex w-full overflow-auto rounded-[8px]  appflowy-scroller border border-line-divider bg-fill-list-active p-5 pt-12`}
          >
            <code>{children}</code>
          </pre>
        </div>
        {showToolbar && <CodeToolbar node={node} />}
      </div>
    );
  }),
  (prevProps, nextProps) => JSON.stringify(prevProps.node) === JSON.stringify(nextProps.node),
);
export default CodeBlock;
