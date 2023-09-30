import { RenderElementProps } from 'slate-react';
import React, { useRef } from 'react';

export function TextElement(props: RenderElementProps) {
  const ref = useRef<HTMLDivElement | null>(null);

  return (
    <div
      {...props.attributes}
      ref={(e) => {
        ref.current = e;
        props.attributes.ref(e);
      }}
    >
      {props.children}
    </div>
  );
}
