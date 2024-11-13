import MentionPage from '@/components/editor/components/leaf/mention/MentionPage';
import { EditorElementProps, SubpageNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useMemo } from 'react';
import { useReadOnly } from 'slate-react';

export const SubPage = memo(
  forwardRef<HTMLDivElement, EditorElementProps<SubpageNode>>(({ node, children, ...attributes }, ref) => {
    const className = useMemo(() => {
      const classList = ['subpage', attributes.className ?? '', 'relative', 'w-full', 'h-full', 'overflow-hidden', 'hover:bg-fill-list-hover', 'rounded-[8px] p-1 cursor-pointer'];

      return classList.join(' ');
    }, [attributes.className]);

    const pageId = node.data.view_id;
    const readOnly = useReadOnly();

    return (
      <div
        {...attributes}
        contentEditable={readOnly ? false : undefined}
        className={className}
      >
        <div
          ref={ref}
          className={'absolute left-0 top-0 h-full w-full select-none caret-transparent'}
        >
          {children}
        </div>
        <MentionPage pageId={pageId} />
      </div>
    );
  }),
);

export default SubPage;