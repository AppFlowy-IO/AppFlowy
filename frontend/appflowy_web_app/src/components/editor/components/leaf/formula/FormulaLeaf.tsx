import { KatexMath } from '@/components/_shared/katex-math';
import { useLeafSelected } from '@/components/editor/components/leaf/leaf.hooks';
import React, { Suspense, useMemo } from 'react';
import { Text } from 'slate';
import { useReadOnly } from 'slate-react';

function FormulaLeaf ({ formula, text }: {
  formula: string;
  text: Text;
}) {
  const { isSelected, select, isCursorAfter, isCursorBefore } = useLeafSelected(text);
  const readonly = useReadOnly();
  const className = useMemo(() => {
    const classList = ['formula-inline', 'relative', 'rounded', 'p-0.5 select-none'];

    if (readonly) classList.push('cursor-default');
    else classList.push('cursor-pointer');
    if (isSelected) classList.push('selected');
    if (isCursorAfter) classList.push('cursor-after');
    if (isCursorBefore) classList.push('cursor-before');
    return classList.join(' ');
  }, [readonly, isSelected, isCursorAfter, isCursorBefore]);

  return (
    <span
      onClick={e => {
        e.preventDefault();
        select();
      }}
      contentEditable={false}
      className={className}
    >
      <Suspense fallback={formula}>

      <KatexMath latex={formula || ''} isInline />
      </Suspense>
    </span>
  );
}

export default FormulaLeaf;