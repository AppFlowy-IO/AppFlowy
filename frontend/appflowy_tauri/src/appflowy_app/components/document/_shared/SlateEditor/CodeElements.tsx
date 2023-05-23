import { RenderLeafProps, RenderElementProps } from 'slate-react';
import { BaseText } from 'slate';

interface CodeLeafProps extends RenderLeafProps {
  leaf: BaseText & {
    bold?: boolean;
    italic?: boolean;
    underline?: boolean;
    strikethrough?: boolean;
    prism_token?: string;
    selection_high_lighted?: boolean;
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

  if (leaf.underline) {
    newChildren = <u>{newChildren}</u>;
  }

  const className = [
    'token',
    leaf.prism_token && leaf.prism_token,
    leaf.strikethrough && 'line-through',
    leaf.selection_high_lighted && 'bg-main-secondary',
  ].filter(Boolean);

  return (
    <span {...attributes} className={className.join(' ')}>
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
