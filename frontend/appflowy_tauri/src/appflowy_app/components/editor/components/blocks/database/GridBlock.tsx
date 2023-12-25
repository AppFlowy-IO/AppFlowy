import React, { forwardRef, memo } from 'react';
import { EditorElementProps, GridNode } from '$app/application/document/document.types';

import GridView from '$app/components/editor/components/blocks/database/GridView';
import DatabaseEmpty from '$app/components/editor/components/blocks/database/DatabaseEmpty';

export const GridBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<GridNode>>(({ node, children, className = '', ...attributes }, ref) => {
    const viewId = node.data.viewId;

    return (
      <div {...attributes} className={`${className} relative my-2`}>
        <div ref={ref} className={'absolute left-0 top-0 h-full w-full caret-transparent'}>
          {children}
        </div>
        <div
          contentEditable={false}
          className='flex h-[400px] overflow-hidden border-b border-t border-line-divider py-3 caret-text-title'
        >
          {viewId ? <GridView viewId={viewId} /> : <DatabaseEmpty node={node} />}
        </div>
      </div>
    );
  })
);

export default GridBlock;
