import React, { useCallback } from 'react';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import { ToggleListNode } from '$app/application/document/document.types';
import { ReactComponent as RightSvg } from '$app/assets/more.svg';

function ToggleIcon({ block, className }: { block: ToggleListNode; className: string }) {
  const editor = useSlateStatic();
  const { collapsed } = block.data;

  const toggleToggleList = useCallback(() => {
    CustomEditor.toggleToggleList(editor, block);
  }, [editor, block]);

  return (
    <span
      data-playwright-selected={false}
      contentEditable={false}
      onClick={toggleToggleList}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} cursor-pointer pr-1 text-xl hover:text-fill-default`}
    >
      {collapsed ? <RightSvg /> : <RightSvg className={'rotate-90 transform'} />}
    </span>
  );
}

export default ToggleIcon;
