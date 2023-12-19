import { forwardRef, memo } from 'react';
import { EditorElementProps, CodeNode } from '$app/application/document/document.types';
import LanguageSelect from './SelectLanguage';

import { useCodeBlock } from '$app/components/editor/components/blocks/code/Code.hooks';

export const Code = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CodeNode>>(({ node, children, ...attributes }, ref) => {
    const { language, handleChangeLanguage } = useCodeBlock(node);

    return (
      <div
        {...attributes}
        ref={ref}
        className={`${
          attributes.className ?? ''
        } my-2 w-full rounded border border-solid border-line-divider bg-content-blue-50 p-6`}
      >
        <div contentEditable={false} className={'mb-2 w-full'}>
          <LanguageSelect language={language} onChangeLanguage={handleChangeLanguage} />
        </div>

        <pre className='code-block-element'>
          <code>{children}</code>
        </pre>
      </div>
    );
  })
);
