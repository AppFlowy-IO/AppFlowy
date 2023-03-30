import { Slate, Editable } from 'slate-react';
import Leaf from './Leaf';
import { useTextBlock } from './TextBlock.hooks';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import NodeComponent from '../Node';
import HoveringToolbar from '../HoveringToolbar';
import { TextDelta } from '@/appflowy_app/interfaces/document';
import React from 'react';

function TextBlock({
  node,
  childIds,
  placeholder,
  delta,
  ...props
}: {
  node: Node;
  delta: TextDelta[];
  childIds?: string[];
  placeholder?: string;
} & React.HTMLAttributes<HTMLDivElement>) {
  const { editor, value, onChange, onKeyDownCapture, onDOMBeforeInput } = useTextBlock(node.data.text!, delta);

  return (
    <div {...props} className={`py-[2px] ${props.className}`}>
      <Slate editor={editor} onChange={onChange} value={value}>
        <HoveringToolbar id={node.id} />
        <Editable
          onKeyDownCapture={onKeyDownCapture}
          onDOMBeforeInput={onDOMBeforeInput}
          renderLeaf={(leafProps) => <Leaf {...leafProps} />}
          placeholder={placeholder || 'Please enter some text...'}
        />
      </Slate>
      {childIds && childIds.length > 0 ? (
        <div className='pl-[1.5em]'>
          {childIds.map((item) => (
            <NodeComponent key={item} id={item} />
          ))}
        </div>
      ) : null}
    </div>
  );
}

export default React.memo(TextBlock);
