import React, { forwardRef, memo, useCallback, useContext } from 'react';
import { EditorElementProps, GridNode } from '$app/application/document/document.types';

import GridView from '$app/components/editor/components/blocks/database/GridView';
import DatabaseEmpty from '$app/components/editor/components/blocks/database/DatabaseEmpty';
import { EditorSelectedBlockContext } from '$app/components/editor/components/editor/Editor.hooks';

export const GridBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<GridNode>>(({ node, children, className = '', ...attributes }, ref) => {
    const viewId = node.data.viewId;

    const blockId = node.blockId;
    const selectedBlockContext = useContext(EditorSelectedBlockContext);
    const onClick = useCallback(() => {
      if (!blockId) return;
      selectedBlockContext.clear();
      selectedBlockContext.add(blockId);
    }, [blockId, selectedBlockContext]);

    return (
      <div {...attributes} onClick={onClick} className={`${className} relative my-2`}>
        <div ref={ref} className={'absolute left-0 top-0 h-full w-full caret-transparent'}>
          {children}
        </div>
        <div
          contentEditable={false}
          className='flex h-[400px] overflow-hidden border-b border-t border-line-divider bg-bg-body py-3 caret-text-title'
        >
          {viewId ? <GridView viewId={viewId} /> : <DatabaseEmpty node={node} />}
        </div>
      </div>
    );
  })
);

export default GridBlock;
