import { Mention } from '@/application/types';
import FormulaLeaf from '@/components/editor/components/leaf/formula/FormulaLeaf';
import { Href } from '@/components/editor/components/leaf/href';
import MentionLeaf from '@/components/editor/components/leaf/mention/MentionLeaf';
import { getFontFamily } from '@/utils/font';
import React, { CSSProperties } from 'react';
import { RenderLeafProps } from 'slate-react';
import { renderColor } from '@/utils/color';

export function Leaf ({ attributes, children, leaf, text }: RenderLeafProps) {
  let newChildren = children;

  const classList = [leaf.prism_token, leaf.prism_token && 'token', leaf.class_name].filter(Boolean);

  if (leaf.code) {
    newChildren = <span className={'bg-line-divider font-medium text-[#EB5757]'}>{newChildren}</span>;
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
    newChildren = <Href leaf={leaf}>{newChildren}</Href>;
  }

  if (leaf.font_family) {
    style['fontFamily'] = getFontFamily(leaf.font_family);
  }

  if (leaf.mention || leaf.formula) {
    style['position'] = 'relative';
    const node = leaf.mention ? <MentionLeaf
      text={text}
      mention={leaf.mention as Mention}
    /> : leaf.formula ? <FormulaLeaf formula={leaf.formula} text={text} /> : null;

    newChildren = <>
      
      {node}
      <span className={'absolute opacity-0 left-0'}>
        {newChildren}
      </span>
    </>;
  }

  return (
    <span {...attributes} style={style} className={`${classList.join(' ')}`}>
      {newChildren}
    </span>
  );
}
