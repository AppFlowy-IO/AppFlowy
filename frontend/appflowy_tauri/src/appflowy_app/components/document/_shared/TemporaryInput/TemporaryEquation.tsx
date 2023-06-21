import React, { useRef } from 'react';
import { Functions } from '@mui/icons-material';
import KatexMath from '$app/components/document/_shared/KatexMath';

function TemporaryEquation({ latex }: { latex: string }) {
  return (
    <span className={'rounded bg-shade-6 px-1 py-0.5'} contentEditable={false}>
      {latex ? (
        <KatexMath latex={latex} isInline />
      ) : (
        <span className={'text-shade-3'}>
          <Functions /> {'New equation'}
        </span>
      )}
    </span>
  );
}

export default TemporaryEquation;
