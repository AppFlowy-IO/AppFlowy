import React, { CSSProperties } from 'react';
import { RenderLeafProps } from 'slate-react';
import { Link } from '$app/components/editor/components/marks';

export function Leaf({ attributes, children, leaf }: RenderLeafProps) {
  let newChildren = children;

  const classList = [
    leaf.prism_token,
    leaf.prism_token && 'token',
    leaf.bold && 'font-bold',
    leaf.italic && 'italic',
    leaf.underline && 'underline',
    leaf.strikethrough && 'line-through',
    leaf.code && 'text-[#EB5757] font-normal rounded-md text-xs px-1 mx-0.5 bg-gray-300 bg-opacity-50',
  ].filter(Boolean);

  const style: CSSProperties = {};

  if (leaf.font_color) {
    style['color'] = leaf.font_color.replace('0x', '#');
  }

  if (leaf.bg_color) {
    style['backgroundColor'] = leaf.bg_color.replace('0x', '#');
  }

  if (leaf.href) {
    newChildren = <Link leaf={leaf}>{newChildren}</Link>;
  }

  return (
    <span {...attributes} style={style} className={classList.join(' ')}>
      {newChildren}
    </span>
  );
}
