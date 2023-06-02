import { RenderLeafProps } from 'slate-react';
import { BaseText } from 'slate';
import { useRef } from 'react';

interface TextLeafProps extends RenderLeafProps {
  leaf: BaseText & {
    bold?: boolean;
    italic?: boolean;
    underline?: boolean;
    strikethrough?: boolean;
    code?: string;
    selection_high_lighted?: boolean;
  };
}

const TextLeaf = (props: TextLeafProps) => {
  const { attributes, children, leaf } = props;

  const ref = useRef<HTMLSpanElement>(null);

  let newChildren = children;
  if (leaf.bold) {
    newChildren = <strong>{children}</strong>;
  }

  if (leaf.italic) {
    newChildren = <em>{newChildren}</em>;
  }

  if (leaf.underline) {
    newChildren = <u>{newChildren}</u>;
  }

  if (leaf.code) {
    newChildren = (
      <span
        className={`bg-custom-code text-main-hovered`}
        style={{
          fontSize: '85%',
          lineHeight: 'normal',
        }}
      >
        {newChildren}
      </span>
    );
  }

  const className = [
    leaf.strikethrough && 'line-through',
    leaf.selection_high_lighted && 'bg-main-secondary',
    leaf.code && 'inline-code',
  ].filter(Boolean);

  return (
    <span ref={ref} {...attributes} className={className.join(' ')}>
      {newChildren}
    </span>
  );
};

export default TextLeaf;
