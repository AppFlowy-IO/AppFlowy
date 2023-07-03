import { ReactEditor, RenderLeafProps } from 'slate-react';
import { BaseText } from 'slate';
import { useCallback, useRef } from 'react';
import TextLink from '../TextLink';
import { converToIndexLength } from '$app/utils/document/slate_editor';
import LinkHighLight from '$app/components/document/_shared/TextLink/LinkHighLight';
import TemporaryInput from '$app/components/document/_shared/TemporaryInput';
import InlineContainer from '$app/components/document/_shared/InlineBlock/InlineContainer';
import { TemporaryType } from '$app/interfaces/document';

interface Attributes {
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strikethrough?: boolean;
  code?: string;
  selection_high_lighted?: boolean;
  href?: string;
  prism_token?: string;
  link_selection_lighted?: boolean;
  link_placeholder?: string;
  temporary?: boolean;
  formula?: string;
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

  if (leaf.formula) {
    const { isLast, text, parent } = children.props;
    const temporaryType = TemporaryType.Equation;
    const data = { latex: leaf.formula };

    newChildren = (
      <InlineContainer
        isLast={isLast}
        isFirst={text === parent.children[0]}
        getSelection={getSelection}
        formula={leaf.formula}
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
    leaf.selection_high_lighted && 'bg-main-secondary',
    leaf.link_selection_lighted && 'text-link bg-main-secondary',
    leaf.code && 'inline-code',
    leaf.bold && 'font-bold',
    leaf.italic && 'italic',
    leaf.underline && 'underline',
  ].filter(Boolean);

  if (leaf.link_placeholder && leaf.text) {
    newChildren = (
      <LinkHighLight leaf={leaf} title={leaf.link_placeholder}>
        {newChildren}
      </LinkHighLight>
    );
  }

  if (leaf.temporary) {
    newChildren = <TemporaryInput leaf={leaf}>{newChildren}</TemporaryInput>;
  }

  return (
    <span ref={ref} {...customAttributes} className={className.join(' ')}>
      {newChildren}
    </span>
  );
};

export default TextLeaf;
