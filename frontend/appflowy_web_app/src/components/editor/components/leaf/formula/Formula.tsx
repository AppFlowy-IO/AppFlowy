import KatexMath from '@/components/_shared/katex-math/KatexMath';
import { EditorElementProps, FormulaNode } from '@/components/editor/editor.type';
import React, { memo, forwardRef } from 'react';
import { useSelected } from 'slate-react';

export const Formula = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<FormulaNode>>(({ node, children, ...attributes }, ref) => {
    const formula = node.data;
    const selected = useSelected();

    return (
      <span
        ref={ref}
        {...attributes}
        contentEditable={false}
        className={`${attributes.className ?? ''} formula-inline relative cursor-pointer rounded px-1 py-0.5 ${
          selected ? 'selected' : ''
        }`}
      >
        <span className={'select-none'} contentEditable={false}>
          <KatexMath latex={formula || ''} isInline />
        </span>

        <span className={'absolute left-0 right-0 h-0 w-0 select-none opacity-0'}>{children}</span>
      </span>
    );
  })
);

export default Formula;
