import { CalloutNode } from '@/components/editor/editor.type';
import React, { useRef } from 'react';
import { IconButton } from '@mui/material';

function CalloutIcon({ node }: { node: CalloutNode }) {
  const ref = useRef<HTMLButtonElement>(null);

  return (
    <>
      <IconButton contentEditable={false} ref={ref} className={`h-8 w-8 p-1`}>
        {node.data.icon}
      </IconButton>
    </>
  );
}

export default React.memo(CalloutIcon);
