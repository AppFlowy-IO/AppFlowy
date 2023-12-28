import React, { forwardRef, memo, useCallback, useMemo } from 'react';
import { EditorElementProps, ToggleListNode } from '$app/application/document/document.types';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { ReactComponent as RightSvg } from '$app/assets/more.svg';
import { CustomEditor } from '$app/components/editor/command';

export const ToggleList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ToggleListNode>>(({ node, children, ...attributes }, ref) => {
    const { collapsed } = node.data;
    const editor = useSlateStatic() as ReactEditor;
    const className = useMemo(() => {
      return `pl-6 ${attributes.className ?? ''} ${collapsed ? 'collapsed' : ''}`;
    }, [attributes.className, collapsed]);
    const toggleToggleList = useCallback(() => {
      CustomEditor.toggleToggleList(editor, node);
    }, [editor, node]);

    return (
      <>
        <span
          data-playwright-selected={false}
          contentEditable={false}
          onClick={toggleToggleList}
          className='absolute cursor-pointer select-none text-xl hover:text-fill-default'
        >
          {collapsed ? <RightSvg /> : <RightSvg className={'rotate-90 transform'} />}
        </span>
        <div {...attributes} ref={ref} className={className}>
          {children}
        </div>
      </>
    );
  })
);
