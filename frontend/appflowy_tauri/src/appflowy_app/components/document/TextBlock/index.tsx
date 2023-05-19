import { Slate, Editable } from 'slate-react';
import Leaf from './Leaf';
import { useTextBlock } from './TextBlock.hooks';
import React from 'react';
import { NestedBlock } from '$app/interfaces/document';
import NodeChildren from '$app/components/document/Node/NodeChildren';

function TextBlock({
  node,
  childIds,
  placeholder,
  className = '',
}: {
  node: NestedBlock;
  childIds?: string[];
  placeholder?: string;
  className?: string;
}) {
  const { editor, value, onChange, ...rest } = useTextBlock(node.id);

  return (
    <>
      <div className={`px-1 py-[2px] ${className}`}>
        <Slate editor={editor} onChange={onChange} value={value}>
          <Editable
            {...rest}
            renderLeaf={(leafProps) => <Leaf {...leafProps} />}
            placeholder={placeholder || 'Please enter some text...'}
          />
        </Slate>
      </div>
      <NodeChildren className='pl-[1.5em]' childIds={childIds} />
    </>
  );
}

export default React.memo(TextBlock);
