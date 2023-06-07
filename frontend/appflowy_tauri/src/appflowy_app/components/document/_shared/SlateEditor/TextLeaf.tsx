import { ReactEditor, RenderLeafProps } from 'slate-react';
import { BaseText } from 'slate';
import { useCallback, useRef } from 'react';
import TextLink from '../TextLink';
import { converToIndexLength } from '$app/utils/document/slate_editor';

interface Attributes {
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strikethrough?: boolean;
  code?: string;
  selection_high_lighted?: boolean;
  href?: string;
  prism_token?: string;
}
interface TextLeafProps extends RenderLeafProps {
  leaf: BaseText & Attributes;
  isCodeBlock?: boolean;
  editor: ReactEditor;
}

const TextLeaf = (props: TextLeafProps) => {
  const { attributes, children, leaf, isCodeBlock, editor } = props;
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

  const getSelection = useCallback(
    (node: Element) => {
      const slateNode = ReactEditor.toSlateNode(editor, node);
      const path = ReactEditor.findPath(editor, slateNode);
      const selection = converToIndexLength(editor, {
        anchor: { path, offset: 0 },
        focus: { path, offset: leaf.text.length },
      });
      return selection;
    },
    [editor, leaf]
  );

  if (leaf.href) {
    newChildren = (
      <TextLink getSelection={getSelection} title={leaf.text} href={leaf.href}>
        {newChildren}
      </TextLink>
    );
  }

  const className = [
    isCodeBlock && 'token',
    leaf.prism_token && leaf.prism_token,
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
