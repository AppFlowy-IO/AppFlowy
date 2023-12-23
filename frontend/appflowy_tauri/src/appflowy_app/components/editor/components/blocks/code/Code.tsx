import { forwardRef, memo } from 'react';
import { EditorElementProps, CodeNode } from '$app/application/document/document.types';
import LanguageSelect from './SelectLanguage';

import { useCodeBlock } from '$app/components/editor/components/blocks/code/Code.hooks';

export const Code = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CodeNode>>(({ node, children, ...attributes }, ref) => {
    const { language, handleChangeLanguage } = useCodeBlock(node);

    return (
      <>
        <div contentEditable={false} className={'absolute w-full px-4 py-2'}>
          <LanguageSelect language={language} onChangeLanguage={handleChangeLanguage} />
        </div>
        <div
          {...attributes}
          ref={ref}
          className={`${
            attributes.className ?? ''
          } my-2 flex w-full flex-col rounded border border-solid border-line-divider bg-content-blue-50 p-6 pt-12`}
        >
          <pre className='code-block-element'>
            <code>{children}</code>
          </pre>
        </div>
      </>
    );
  })
);
