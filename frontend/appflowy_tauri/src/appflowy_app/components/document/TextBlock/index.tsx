import { Slate, Editable } from 'slate-react';
import Leaf from './Leaf';
import { useTextBlock } from './TextBlock.hooks';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import NodeComponent from '../Node';
import HoveringToolbar from '../HoveringToolbar';

export default function TextBlock({
  node,
  childIds,
  placeholder,
  ...props
}: {
  node: Node;
  childIds?: string[];
  placeholder?: string;
} & React.HTMLAttributes<HTMLDivElement>) {
  const { editor, value, onChange, onKeyDownCapture, onDOMBeforeInput } = useTextBlock(node.data.text!, node.delta);

  return (
    <div {...props} className={props.className}>
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
