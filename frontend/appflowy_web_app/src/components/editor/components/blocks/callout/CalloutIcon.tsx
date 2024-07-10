import { CalloutNode } from '@/components/editor/editor.type';
import React, { useRef } from 'react';

function CalloutIcon({ node }: { node: CalloutNode }) {
  const ref = useRef<HTMLButtonElement>(null);

  return (
    <>
      <span contentEditable={false} ref={ref} className={`icon flex h-8 w-8 items-center p-1`}>
        {node.data.icon}
      </span>
    </>
  );
}

export default React.memo(CalloutIcon);
