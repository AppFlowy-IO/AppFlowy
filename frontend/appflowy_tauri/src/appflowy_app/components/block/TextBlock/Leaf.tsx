import { RenderLeafProps } from 'slate-react';

const Leaf = ({ attributes, children, leaf }: RenderLeafProps) => {
  let newChildren = children;
  if ('bold' in leaf && leaf.bold) {
    newChildren = <strong>{children}</strong>;
  }

  if ('code' in leaf && leaf.code) {
    newChildren = <code className='rounded-sm	 bg-[#F2FCFF] p-1'>{newChildren}</code>;
  }

  if ('italic' in leaf && leaf.italic) {
    newChildren = <em>{newChildren}</em>;
  }

  if ('underlined' in leaf && leaf.underlined) {
    newChildren = <u>{newChildren}</u>;
  }

  return (
    <span {...attributes} className={'strikethrough' in leaf && leaf.strikethrough ? `line-through` : ''}>
      {newChildren}
    </span>
  );
};

export default Leaf;
