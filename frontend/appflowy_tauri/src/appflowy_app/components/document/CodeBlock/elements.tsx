import { RenderLeafProps, RenderElementProps } from 'slate-react';
import { BaseText } from 'slate';

export const CodeLeaf = (
  props: RenderLeafProps & {
    leaf: BaseText & {
      bold?: boolean;
      italic?: boolean;
      underlined?: boolean;
      strikethrough?: boolean;
      prism_token?: string;
    };
  }
) => {
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

  return (
    <span {...attributes} className={`token ${leaf.prism_token} ${leaf.strikethrough ? `line-through` : ''}`}>
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
