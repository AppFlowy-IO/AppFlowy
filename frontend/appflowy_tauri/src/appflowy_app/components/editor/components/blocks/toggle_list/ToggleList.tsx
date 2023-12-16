import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, ToggleListNode } from '$app/application/document/document.types';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { ReactComponent as RightSvg } from '$app/assets/more.svg';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { CustomEditor } from '$app/components/editor/command';

export const ToggleList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ToggleListNode>>(({ node, children, ...attributes }, ref) => {
    const { collapsed } = node.data;
    const editor = useSlateStatic() as ReactEditor;
    const className = useMemo(() => {
      return `relative ${attributes.className ?? ''}`;
    }, [attributes.className]);

    return (
      <div {...attributes} ref={ref} className={className}>
        <span
          contentEditable={false}
          onClick={() => CustomEditor.toggleToggleList(editor, node)}
          className='absolute left-0 top-0 inline-block cursor-pointer rounded text-xl text-text-title hover:bg-fill-list-hover'
        >
          {collapsed ? <RightSvg /> : <RightSvg className={'rotate-90 transform'} />}
        </span>
        <span className={'z-1 relative ml-6'}>
          <Placeholder node={node} />

          {children}
        </span>
      </div>
    );
  })
);
