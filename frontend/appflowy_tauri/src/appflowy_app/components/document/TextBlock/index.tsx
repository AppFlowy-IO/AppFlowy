import React from 'react';
import { NestedBlock } from '$app/interfaces/document';
import Editor from '../_shared/SlateEditor/TextEditor';
import { useChange } from '$app/components/document/_shared/EditorHooks/useChange';
import NodeChildren from '$app/components/document/Node/NodeChildren';
import { useKeyDown } from '$app/components/document/TextBlock/useKeyDown';
import { useSelection } from '$app/components/document/_shared/EditorHooks/useSelection';

interface Props {
  node: NestedBlock;
  childIds?: string[];
  placeholder?: string;
}
function TextBlock({ node, childIds, placeholder }: Props) {
  const { value, onChange } = useChange(node);
  const { onSelectionChange, selection, lastSelection } = useSelection(node.id);
  const { onKeyDown } = useKeyDown(node.id);

  return (
    <>
      <Editor
        value={value}
        onChange={onChange}
        onSelectionChange={onSelectionChange}
        selection={selection}
        lastSelection={lastSelection}
        onKeyDown={onKeyDown}
        placeholder={placeholder}
      />
      <NodeChildren className='pl-[1.5em]' childIds={childIds} />
    </>
  );
}

export default React.memo(TextBlock);
