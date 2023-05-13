import { RenderLeafProps, RenderElementProps } from 'slate-react';
import { BaseText } from 'slate';

interface CodeLeafProps extends RenderLeafProps {
  leaf: BaseText & {
    bold?: boolean;
    italic?: boolean;
    underlined?: boolean;
    strikethrough?: boolean;
    prism_token?: string;
    selectionHighlighted?: boolean;
  };
}

export const CodeLeaf = (props: CodeLeafProps) => {
  const { attributes, children, leaf } = props;

  let newChildren = children;
  if (leaf.bold) {
    newChildren = <strong>{children}</strong>;
  }

  if (leaf.italic) {
    newChildren = <em>{newChildren}</em>;
  }

  if (leaf.underlined) {
    newChildren = <u>{newChildren}</u>;
  }

  let className = 'token';
  if (leaf.prism_token) {
    className += ` ${leaf.prism_token}`;
  }
  if (leaf.strikethrough) {
    className += ' line-through';
  }
  if (leaf.selectionHighlighted) {
    className += ' bg-main-secondary';
  }

  return (
    <span {...attributes} className={className}>
      {newChildren}
    </span>
  );
};

export const CodeBlockElement = (props: RenderElementProps) => {
  return (
    <pre className='code-block-element' {...props.attributes}>
      <code>{props.children}</code>
    </pre>
  );
};
