import React, { CSSProperties } from 'react';
import { Editor, Element } from 'slate';
import { useSlateStatic } from 'slate-react';
import PlaceholderContent from '$app/components/editor/components/blocks/_shared/PlaceholderContent';

function Placeholder({ node, ...props }: { node: Element; className?: string; style?: CSSProperties }) {
  const editor = useSlateStatic();
  const isEmpty = Editor.isEmpty(editor, node);

  if (!isEmpty) {
    return null;
  }

  return <PlaceholderContent node={node} {...props} />;
}

export default React.memo(Placeholder);
