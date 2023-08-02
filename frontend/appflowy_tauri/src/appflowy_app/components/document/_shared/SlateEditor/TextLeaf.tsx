import { ReactEditor, RenderLeafProps } from 'slate-react';
import { BaseText } from 'slate';
import { useCallback, useRef } from 'react';
import { converToIndexLength } from '$app/utils/document/slate_editor';
import TemporaryInput from '$app/components/document/_shared/TemporaryInput';
import InlineContainer from '$app/components/document/_shared/InlineBlock/InlineContainer';
import { TemporaryType } from '$app/interfaces/document';
import LinkInline from '$app/components/document/_shared/InlineBlock/LinkInline';

interface Attributes {
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strikethrough?: boolean;
  code?: string;
  selection_high_lighted?: boolean;
  href?: string;
  prism_token?: string;
  temporary?: boolean;
  formula?: string;
  font_color?: string;
  bg_color?: string;
}
interface TextLeafProps extends RenderLeafProps {
  leaf: BaseText & Attributes;
  isCodeBlock?: boolean;
  editor: ReactEditor;
}

const TextLeaf = (props: TextLeafProps) => {
  const { attributes, children, leaf, isCodeBlock, editor } = props;
  const ref = useRef<HTMLSpanElement>(null);

  const customAttributes = {
    ...attributes,
  };
  let newChildren = children;

  if (leaf.code && !leaf.temporary) {
    newChildren = (
      <span
        className={`bg-content-blue-50 text-text-title`}
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
      <LinkInline
        temporaryType={TemporaryType.Link}
        getSelection={getSelection}
        selectedText={leaf.text}
        data={{
          href: leaf.href,
        }}
      >
        {newChildren}
      </LinkInline>
    );
  }

  if (leaf.formula) {
    const { isLast, text, parent } = children.props;
    const temporaryType = TemporaryType.Equation;
    const data = { latex: leaf.formula };

    newChildren = (
      <InlineContainer
        isLast={isLast}
        isFirst={text === parent.children[0]}
        getSelection={getSelection}
        data={data}
        temporaryType={temporaryType}
        selectedText={leaf.text}
      >
        {newChildren}
      </InlineContainer>
    );
  }

  const className = [
    isCodeBlock && 'token',
    leaf.prism_token && leaf.prism_token,
    leaf.strikethrough && 'line-through',
    leaf.selection_high_lighted && 'bg-content-blue-100',
    leaf.code && !leaf.temporary && 'inline-code',
    leaf.bold && 'font-bold',
    leaf.italic && 'italic',
    leaf.underline && 'underline',
  ].filter(Boolean);

  if (leaf.temporary) {
    newChildren = (
      <TemporaryInput getSelection={getSelection} leaf={leaf}>
        {newChildren}
      </TemporaryInput>
    );
  }

  return (
    <span
      style={{
        backgroundColor: leaf.bg_color,
        color: leaf.font_color,
      }}
      ref={ref}
      {...customAttributes}
      className={className.join(' ')}
    >
      {newChildren}
    </span>
  );
};

export default TextLeaf;
