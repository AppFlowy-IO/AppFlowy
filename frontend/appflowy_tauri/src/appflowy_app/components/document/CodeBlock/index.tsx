import { BlockType, NestedBlock } from '$app/interfaces/document';
import React from 'react';
import SelectLanguage from './SelectLanguage';
import { useChange } from '$app/components/document/_shared/EditorHooks/useChange';
import { useKeyDown } from './useKeyDown';
import CodeEditor from '$app/components/document/_shared/SlateEditor/CodeEditor';
import { useSelection } from '$app/components/document/_shared/EditorHooks/useSelection';

export default function CodeBlock({
  node,
  placeholder,
  ...props
}: { node: NestedBlock<BlockType.CodeBlock>; placeholder?: string } & React.HTMLAttributes<HTMLDivElement>) {
  const id = node.id;
  const language = node.data.language;
  const onKeyDown = useKeyDown(id);
  const className = props.className ? ` ${props.className}` : '';
  const { value, onChange } = useChange(node);
  const { onSelectionChange, selection, lastSelection } = useSelection(id);
  return (
    <div {...props} className={`rounded bg-shade-6 p-6 ${className}`}>
      <div className={'mb-2 w-[100%]'}>
        <SelectLanguage id={id} language={language} />
      </div>
      <CodeEditor
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        language={language}
        onKeyDown={onKeyDown}
        onSelectionChange={onSelectionChange}
        selection={selection}
        lastSelection={lastSelection}
      />
    </div>
  );
}
