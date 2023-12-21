import React from 'react';
import KatexMath from '$app/components/_shared/KatexMath';

function FormulaLeaf({ text, children }: { text: string; children: React.ReactNode }) {
  return (
    <span className={'relative'}>
      <KatexMath latex={text || ''} isInline />
      <span className={'absolute left-0 right-0 h-0 w-0 opacity-0'}>{children}</span>
    </span>
  );
}

export default FormulaLeaf;
