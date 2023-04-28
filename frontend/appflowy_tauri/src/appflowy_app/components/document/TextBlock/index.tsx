import { Slate, Editable } from 'slate-react';
import Leaf from './Leaf';
import { useTextBlock } from './TextBlock.hooks';
import NodeComponent from '../Node';
import BlockHorizontalToolbar from '../BlockHorizontalToolbar';
import React from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';

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
  return (
    <>
      <div {...props} className={`py-[2px] ${props.className}`}>
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
      {childIds && childIds.length > 0 ? (
        <div className='pl-[1.5em]'>
          {childIds.map((item) => (
            <NodeComponent key={item} id={item} />
          ))}
        </div>
      ) : null}
    </>
  );
}

export default React.memo(TextBlock);
