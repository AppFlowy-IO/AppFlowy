import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { ToggleListNode } from '@/components/editor/editor.type';
import { debounce } from 'lodash-es';
import React, { useCallback, useMemo } from 'react';
import { ReactComponent as ExpandSvg } from '$icons/16x/drop_menu_show.svg';
import { useReadOnly, useSlateStatic } from 'slate-react';

function ToggleIcon ({ block, className }: { block: ToggleListNode; className: string }) {
  const { collapsed } = block.data;
  const editor = useSlateStatic();
  const readOnly = useReadOnly();

  const toggleCollapsed = useMemo(() => {
    if (readOnly) {
      return;
    }

    return debounce(() => {
      CustomEditor.toggleToggleList(editor as YjsEditor, block.blockId);
    }, 100);
  }, [readOnly, editor, block.blockId]);

  const handleClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    toggleCollapsed?.();
  }, [toggleCollapsed]);

  return (
    <span
      onClick={handleClick}
      data-playwright-selected={false}
      contentEditable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} ${readOnly ? '' : 'cursor-pointer hover:text-fill-default'} pr-1 text-xl`}
    >
      {collapsed ? <ExpandSvg className={'-rotate-90 transform'} /> : <ExpandSvg />}
    </span>
  );
}

export default ToggleIcon;
