import React from 'react';
import KatexMath from '$app/components/_shared/katex_math/KatexMath';

function FormulaLeaf({ formula, children }: { formula: string; children: React.ReactNode }) {
  return (
    <span className={'relative'}>
      <span className={'select-none'} contentEditable={false}>
        <KatexMath latex={formula || ''} isInline />
      </span>

      <span className={'absolute left-0 right-0 h-0 w-0 opacity-0'}>{children}</span>
    </span>
  );
}

export default FormulaLeaf;
