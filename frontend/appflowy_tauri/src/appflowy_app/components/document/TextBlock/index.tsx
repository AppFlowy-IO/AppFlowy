import { Slate, Editable } from 'slate-react';
import Leaf from './Leaf';
import { useTextBlock } from './TextBlock.hooks';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import NodeComponent from '../Node';
import HoveringToolbar from '../_shared/HoveringToolbar';
import React, { useMemo } from 'react';

function TextBlock({
  node,
  childIds,
  placeholder,
  ...props
}: {
  node: Node;
  childIds?: string[];
  placeholder?: string;
} & React.HTMLAttributes<HTMLDivElement>) {
  const delta = useMemo(() => node.data.delta || [], [node.data.delta]);
  const { editor, value, onChange, onKeyDownCapture, onDOMBeforeInput } = useTextBlock(delta);

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
