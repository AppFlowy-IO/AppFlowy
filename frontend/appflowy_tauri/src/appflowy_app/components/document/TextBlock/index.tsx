import { Slate, Editable } from 'slate-react';
import Leaf from './Leaf';
import { useTextBlock } from './TextBlock.hooks';
import BlockHorizontalToolbar from '../BlockHorizontalToolbar';
import React from 'react';
import { NestedBlock } from '$app/interfaces/document';
import NodeChildren from '$app/components/document/Node/NodeChildren';

function TextBlock({
  node,
  childIds,
  placeholder,
  ...props
}: {
  node: NestedBlock;
  childIds?: string[];
  placeholder?: string;
} & React.HTMLAttributes<HTMLDivElement>) {
  const { editor, value, onChange, onKeyDownCapture, onDOMBeforeInput } = useTextBlock(node.id);
  const className = props.className !== undefined ? ` ${props.className}` : '';

  return (
    <>
      <div {...props} className={`py-[2px]${className}`}>
        <Slate editor={editor} onChange={onChange} value={value}>
          <BlockHorizontalToolbar id={node.id} />
          <Editable
            onKeyDownCapture={onKeyDownCapture}
            onDOMBeforeInput={onDOMBeforeInput}
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
