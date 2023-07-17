import React from 'react';
import 'katex/dist/katex.min.css';
import { BlockMath, InlineMath } from 'react-katex';
import './index.css';

function KatexMath({ latex, isInline = false }: { latex: string; isInline?: boolean }) {
  return isInline ? <InlineMath math={latex} /> : <BlockMath math={latex} />;
}

export default KatexMath;
