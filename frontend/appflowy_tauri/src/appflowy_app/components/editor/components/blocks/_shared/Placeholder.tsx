import React from 'react';
import { Element } from 'slate';
import PlaceholderContent from '$app/components/editor/components/blocks/_shared/PlaceholderContent';

function Placeholder({ node, isEmpty }: { node: Element; isEmpty: boolean }) {
  if (!isEmpty) {
    return null;
  }

  return <PlaceholderContent node={node} />;
}

export default React.memo(Placeholder);
