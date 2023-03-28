import { BaseText } from 'slate';
import { RenderLeafProps } from 'slate-react';

const Leaf = ({
  attributes,
  children,
  leaf,
}: RenderLeafProps & {
  leaf: BaseText & {
    bold?: boolean;
    code?: boolean;
    italic?: boolean;
    underlined?: boolean;
    strikethrough?: boolean;
  };
}) => {
  let newChildren = children;
  if (leaf.bold) {
    newChildren = <strong>{children}</strong>;
  }

  if (leaf.code) {
    newChildren = <code className='rounded-sm	 bg-[#F2FCFF] p-1'>{newChildren}</code>;
  }

  if (leaf.italic) {
    newChildren = <em>{newChildren}</em>;
  }

  if (leaf.underlined) {
    newChildren = <u>{newChildren}</u>;
  }

  return (
    <span {...attributes} className={leaf.strikethrough ? `line-through` : ''}>
      {newChildren}
    </span>
  );
};

export default Leaf;
