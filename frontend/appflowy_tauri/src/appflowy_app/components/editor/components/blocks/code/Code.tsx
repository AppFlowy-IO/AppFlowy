import { forwardRef, memo, useCallback } from 'react';
import { EditorElementProps, CodeNode } from '$app/application/document/document.types';
import LanguageSelect from './SelectLanguage';

import { useCodeBlock } from '$app/components/editor/components/blocks/code/Code.hooks';
import { ReactEditor, useSlateStatic } from 'slate-react';

export const Code = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CodeNode>>(({ node, children, ...attributes }, ref) => {
    const { language, handleChangeLanguage } = useCodeBlock(node);

    const editor = useSlateStatic();
    const onBlur = useCallback(() => {
      const path = ReactEditor.findPath(editor, node);

      ReactEditor.focus(editor);
      editor.select(path);
      editor.collapse({
        edge: 'start',
      });
    }, [editor, node]);

    return (
      <>
        <div contentEditable={false} className={'absolute mt-2 flex h-20 w-full select-none items-center px-6'}>
          <LanguageSelect onBlur={onBlur} language={language} onChangeLanguage={handleChangeLanguage} />
        </div>
        <div {...attributes} ref={ref} className={`${attributes.className ?? ''} flex w-full bg-bg-body py-2`}>
          <pre
            spellCheck={false}
            className={`flex w-full rounded border border-solid border-line-divider bg-content-blue-50 p-5 pt-20`}
          >
            <code>{children}</code>
          </pre>
        </div>
      </>
    );
  })
);
