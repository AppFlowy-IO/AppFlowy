import React, { forwardRef, memo } from 'react';
import { EditorElementProps, GridNode } from '$app/application/document/document.types';

import GridView from '$app/components/editor/components/blocks/database/GridView';
import DatabaseEmpty from '$app/components/editor/components/blocks/database/DatabaseEmpty';

export const GridBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<GridNode>>(({ node, children }, ref) => {
    const viewId = node.data.viewId;

    return (
      <div
        contentEditable={false}
        className='relative flex h-[400px] overflow-hidden border-b border-t border-line-divider caret-text-title'
        ref={ref}
      >
        {viewId ? <GridView viewId={viewId} /> : <DatabaseEmpty node={node} />}

        <div className={'invisible absolute'}>{children}</div>
      </div>
    );
  })
);

export default GridBlock;
