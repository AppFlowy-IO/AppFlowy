import { ReactEditor, RenderLeafProps } from 'slate-react';
import { BaseText } from 'slate';
import { useCallback, useRef } from 'react';
import { converToIndexLength } from '$app/utils/document/slate_editor';
import TemporaryInput from '$app/components/document/_shared/TemporaryInput';
import FormulaInline from '$app/components/document/_shared/InlineBlock/FormulaInline';
import { TemporaryType } from '$app/interfaces/document';
import LinkInline from '$app/components/document/_shared/InlineBlock/LinkInline';
import { MentionType } from '$app_reducers/document/async-actions/mention';
import PageInline from '$app/components/document/_shared/InlineBlock/PageInline';
import { FakeCursorContainer } from '$app/components/document/_shared/InlineBlock/FakeCursorContainer';
import CodeInline from '$app/components/document/_shared/InlineBlock/CodeInline';

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
  mention?: Record<string, string>;
}
interface TextLeafProps extends RenderLeafProps {
  leaf: BaseText & Attributes;
  isCodeBlock?: boolean;
  editor: ReactEditor;
}

const TextLeaf = (props: TextLeafProps) => {
  const { attributes, children, leaf, isCodeBlock, editor } = props;
  const ref = useRef<HTMLSpanElement>(null);
  const { isLast, text, parent } = children.props;
  const isSelected = Boolean(leaf.selection_high_lighted);

  const isFirst = text === parent?.children?.[0];
  const customAttributes = {
    ...attributes,
  };
  let newChildren = children;

  if (leaf.code && !leaf.temporary) {
    newChildren = (
      <CodeInline selected={isSelected} text={text}>
        {newChildren}
      </CodeInline>
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

  if (leaf.formula && leaf.text) {
    const data = { latex: leaf.formula };

    newChildren = (
      <FormulaInline isLast={isLast} isFirst={isFirst} getSelection={getSelection} data={data} selectedText={leaf.text}>
        {newChildren}
      </FormulaInline>
    );
  }

  const mention = leaf.mention;

  if (mention && mention.type === MentionType.PAGE && leaf.text) {
    newChildren = (
      <FakeCursorContainer
        getSelection={getSelection}
        isFirst={isFirst}
        isLast={isLast}
        renderNode={() => <PageInline pageId={mention.page} />}
      >
        {newChildren}
      </FakeCursorContainer>
    );
  }

  const className = [
    isCodeBlock && 'token',
    leaf.prism_token && leaf.prism_token,
    isSelected && 'bg-content-blue-100',
    leaf.bold && 'font-bold',
    leaf.italic && 'italic',
    leaf.underline && 'underline',
    leaf.strikethrough && 'line-through',
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
