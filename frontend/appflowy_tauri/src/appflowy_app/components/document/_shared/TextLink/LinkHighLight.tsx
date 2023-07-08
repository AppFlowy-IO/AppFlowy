import React from 'react';
import { isOverlappingPrefix } from '$app/utils/document/temporary';

function LinkHighLight({ children, leaf, title }: { leaf: { text: string }; title: string; children: React.ReactNode }) {
  return (
    <>
      {leaf.text === title || isOverlappingPrefix(leaf.text, title) ? (
        <span contentEditable={false}>{title}</span>
      ) : null}

      <span className={'absolute opacity-0'}>{children}</span>
    </>
  );
}

export default LinkHighLight;
