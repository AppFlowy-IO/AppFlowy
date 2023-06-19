import { RenderElementProps } from 'slate-react';

export const CodeBlockElement = (props: RenderElementProps) => {
  return (
    <pre className='code-block-element' {...props.attributes}>
      <code>{props.children}</code>
    </pre>
  );
};
