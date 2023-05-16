import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useCodeBlock } from './CodeBlock.hooks';
import { Editable, Slate } from 'slate-react';
import React from 'react';
import { CodeLeaf, CodeBlockElement } from './elements';
import SelectLanguage from './SelectLanguage';
import { decorateCodeFunc } from '$app/utils/document/blocks/code/decorate';

export default function CodeBlock({
  node,
  placeholder,
  ...props
}: { node: NestedBlock<BlockType.CodeBlock>; placeholder?: string } & React.HTMLAttributes<HTMLDivElement>) {
  const { editor, value, onChange, ...rest } = useCodeBlock(node);

  const className = props.className ? ` ${props.className}` : '';
  const id = node.id;
  const language = node.data.language;
  return (
    <div {...props} className={`rounded bg-shade-6 p-6 ${className}`}>
      <div className={'mb-2 w-[100%]'}>
        <SelectLanguage id={id} language={language} />
      </div>
      <Slate editor={editor} onChange={onChange} value={value}>
        <Editable
          {...rest}
          decorate={(entry) => {
            const codeRange = decorateCodeFunc(entry, language);
            const range = rest.decorate(entry);
            return [...range, ...codeRange];
          }}
          renderLeaf={CodeLeaf}
          renderElement={CodeBlockElement}
          placeholder={placeholder || 'Please enter some text...'}
        />
      </Slate>
    </div>
  );
}
