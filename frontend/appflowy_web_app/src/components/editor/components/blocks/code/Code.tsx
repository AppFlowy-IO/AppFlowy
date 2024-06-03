import { useCodeBlock } from '@/components/editor/components/blocks/code/Code.hooks';
import { CodeNode, EditorElementProps } from '@/components/editor/editor.type';
import { forwardRef, memo } from 'react';
import LanguageSelect from './SelectLanguage';

export const CodeBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CodeNode>>(({ node, children, ...attributes }, ref) => {
    const { language, handleChangeLanguage } = useCodeBlock(node);

    return (
      <>
        <div contentEditable={false} className={'absolute mt-2 flex h-20 w-full select-none items-center px-6'}>
          <LanguageSelect readOnly language={language} onChangeLanguage={handleChangeLanguage} />
        </div>
        <div {...attributes} ref={ref} className={`${attributes.className ?? ''} flex w-full bg-bg-body py-2`}>
          <pre
            spellCheck={false}
            className={`flex w-full rounded border border-line-divider bg-fill-list-active p-5 pt-20`}
          >
            <code>{children}</code>
          </pre>
        </div>
      </>
    );
  })
);
