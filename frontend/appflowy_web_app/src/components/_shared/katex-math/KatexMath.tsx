import React from 'react';
import 'katex/dist/katex.min.css';
import { BlockMath, InlineMath } from 'react-katex';
import './index.css';

function KatexMath({ latex, isInline = false }: { latex: string; isInline?: boolean }) {

  return isInline ? (
    <InlineMath renderError={(error) => {
      return (
        <span className="text-red-500">{error.name}: {error.message}</span>
      );
    }}>
      {latex}
    </InlineMath>
  ) : (
    <BlockMath
      renderError={(error) => {
        return (
          <div className="flex h-[51px] items-center justify-center">
            {error.name}: {error.message}
          </div>
        );
      }}
    >
      {latex}
    </BlockMath>
  );
}

export default KatexMath;
