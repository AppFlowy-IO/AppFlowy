import { useCodeBlock } from '@/components/editor/components/blocks/code/Code.hooks';
import CodeToolbar from './CodeToolbar';
import { CodeNode, EditorElementProps } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useState, lazy, Suspense } from 'react';
import { ReactEditor, useReadOnly, useSlateStatic } from 'slate-react';
import LanguageSelect from './SelectLanguage';
import { Element } from 'slate';

const MermaidChat = lazy(() => import('./MermaidChat'));

export const CodeBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CodeNode>>(({ node, children, ...attributes }, ref) => {
    const { language, handleChangeLanguage } = useCodeBlock(node);
    const [showToolbar, setShowToolbar] = useState(false);

    const editor = useSlateStatic();
    const readOnly = useReadOnly() || editor.isElementReadOnly(node as unknown as Element);

    return (
      <div
        className={'relative w-full'}
        onMouseEnter={() => {
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
      >
        {<div
          contentEditable={false}
          style={{
            visibility: showToolbar ? 'visible' : 'hidden',
          }}
          className={'absolute flex h-12 w-full select-none items-center px-2'}
        >
          <LanguageSelect
            readOnly={readOnly}
            language={language}
            onChangeLanguage={handleChangeLanguage}
            onClose={() => {
              window.getSelection()?.removeAllRanges();
              ReactEditor.focus(editor);
              const path = ReactEditor.findPath(editor, node);

              editor.select(editor.start(path));
            }}
          />
        </div>}

        <div
          {...attributes}
          ref={ref}
          className={`${attributes.className ?? ''} flex w-full`}
        >
          <pre
            spellCheck={false}
            className={`flex w-full flex-col overflow-auto rounded-[8px]  appflowy-scroller border border-line-divider bg-fill-list-active p-5 pt-12`}
          >
            <code>{children}</code>
            {language === 'mermaid' && <Suspense><MermaidChat
              node={node}
            /></Suspense>}
          </pre>
        </div>

        {showToolbar && <CodeToolbar node={node}/>}
      </div>
    );
  }),
  (prevProps, nextProps) => JSON.stringify(prevProps.node) === JSON.stringify(nextProps.node),
);
export default CodeBlock;
