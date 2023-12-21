import React, { CSSProperties } from 'react';
import { RenderLeafProps } from 'slate-react';
import { Link } from '$app/components/editor/components/marks';

export function Leaf({ attributes, children, leaf }: RenderLeafProps) {
  let newChildren = children;

  const classList = [leaf.prism_token, leaf.prism_token && 'token'].filter(Boolean);

  if (leaf.code) {
    newChildren = (
      <code className={'mx-0.5 rounded-sm bg-gray-300 bg-opacity-50 px-1 text-xs font-normal text-[#EB5757]'}>
        {newChildren}
      </code>
    );
  }

  if (leaf.underline) {
    newChildren = <u>{newChildren}</u>;
  }

  if (leaf.strikethrough) {
    newChildren = <s>{newChildren}</s>;
  }

  if (leaf.italic) {
    newChildren = <em>{newChildren}</em>;
  }

  if (leaf.bold) {
    newChildren = <strong>{newChildren}</strong>;
  }

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
    <span {...attributes} style={style} className={`${classList.join(' ')}`}>
      {newChildren}
    </span>
  );
}
