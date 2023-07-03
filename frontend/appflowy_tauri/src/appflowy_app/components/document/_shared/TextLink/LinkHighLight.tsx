import React from 'react';
import { isOverlappingPrefix } from '$app/utils/document/temporary';

function LinkHighLight({ children, leaf, title }: { leaf: { text: string }; title: string; children: React.ReactNode }) {
  return (
    <>
      {leaf.text === title || isOverlappingPrefix(leaf.text, title) ? (
        <span contentEditable={false}>{title}</span>
      ) : null}

      <span
        style={{
          display: 'none',
        }}
      >
        {children}
      </span>
    </>
  );
}

export default LinkHighLight;
