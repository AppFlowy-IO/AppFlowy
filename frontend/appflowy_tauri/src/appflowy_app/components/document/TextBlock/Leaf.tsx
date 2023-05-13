import { BaseText } from 'slate';
import { RenderLeafProps } from 'slate-react';
interface LeafProps extends RenderLeafProps {
  leaf: BaseText & {
    bold?: boolean;
    code?: boolean;
    italic?: boolean;
    underlined?: boolean;
    strikethrough?: boolean;
    selectionHighlighted?: boolean;
  };
}
const Leaf = ({ attributes, children, leaf }: LeafProps) => {
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

  const className = [leaf.strikethrough && 'line-through', leaf.selectionHighlighted && 'bg-main-secondary'].filter(
    Boolean
  );

  return (
    <span {...attributes} className={className.join(' ')}>
      {newChildren}
    </span>
  );
};

export default Leaf;
