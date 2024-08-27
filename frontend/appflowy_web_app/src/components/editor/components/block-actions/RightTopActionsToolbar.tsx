import RightTopActions, { RightTopActionsProps } from '@/components/editor/components/block-actions/RightTopActions';
import React, { useRef } from 'react';

interface RightTopActionsToolbarProps extends RightTopActionsProps {
  style?: React.CSSProperties;
}

function RightTopActionsToolbar ({ style, ...props }: RightTopActionsToolbarProps) {
  const ref = useRef<HTMLDivElement | null>(null);

  return (
    <div ref={ref} style={style} contentEditable={false} className={`block-actions absolute right-2 top-2 z-10`}>
      <RightTopActions {...props} />
    </div>
  );
}

export default RightTopActionsToolbar;
