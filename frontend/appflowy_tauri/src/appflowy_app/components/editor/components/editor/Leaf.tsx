import React, { CSSProperties } from 'react';
import { RenderLeafProps } from 'slate-react';
import { Link } from '$app/components/editor/components/inline_nodes/link';
import { renderColor } from '$app/utils/color';

export function Leaf({ attributes, children, leaf }: RenderLeafProps) {
  let newChildren = children;

  const classList = [leaf.prism_token, leaf.prism_token && 'token', leaf.class_name].filter(Boolean);

  if (leaf.code) {
    newChildren = (
      <code
        style={{
          fontSize: '0.85em',
        }}
        className={'bg-fill-list-active bg-opacity-50 font-normal tracking-wider text-[#EB5757]'}
      >
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
    style['color'] = renderColor(leaf.font_color);
  }

  if (leaf.bg_color) {
    style['backgroundColor'] = renderColor(leaf.bg_color);
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
