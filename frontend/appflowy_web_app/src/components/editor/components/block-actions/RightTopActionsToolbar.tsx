import RightTopActions from '@/components/editor/components/block-actions/RightTopActions';
import React, { useRef } from 'react';

function RightTopActionsToolbar({ onCopy, style }: { onCopy: () => void; style?: React.CSSProperties }) {
  const ref = useRef<HTMLDivElement | null>(null);

  return (
    <div ref={ref} style={style} contentEditable={false} className={`block-actions absolute right-2 top-2 z-10`}>
      <RightTopActions onCopy={onCopy} />
    </div>
  );
}

export default RightTopActionsToolbar;
