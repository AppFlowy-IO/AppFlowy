import { extractHeadings, nestHeadings } from '@/components/editor/components/blocks/outline/utils';
import { EditorElementProps, HeadingNode, OutlineNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlate } from 'slate-react';
import smoothScrollIntoViewIfNeeded from 'smooth-scroll-into-view-if-needed';

export const Outline = memo(
  forwardRef<HTMLDivElement, EditorElementProps<OutlineNode>>(({ node, children, className, ...attributes }, ref) => {
    const editor = useSlate();
    const [root, setRoot] = useState<HeadingNode[]>([]);
    const { t } = useTranslation();

    useEffect(() => {
      const root = nestHeadings(extractHeadings(editor, node.data.depth || 6));

      setRoot(root);
    }, [editor, node.data.depth]);

    const jumpToHeading = useCallback((heading: HeadingNode) => {
      const id = `heading-${heading.blockId}`;

      const element = document.getElementById(id);

      if (element) {
        void smoothScrollIntoViewIfNeeded(element, {
          behavior: 'smooth',
          block: 'start',
        });
      }
    }, []);

    const renderHeading = useCallback(
      (heading: HeadingNode, index: number) => {
        const children = (heading.children as HeadingNode[]).map(renderHeading);
        const { text, level } = heading.data as { text: string; level: number };

        return (
          <div
            onClick={(e) => {
              e.stopPropagation();
              jumpToHeading(heading);
            }}
            className={`my-1 ml-4 `}
            key={`${level}-${index}`}
          >
            <div className={'cursor-pointer rounded px-2 underline hover:text-content-blue-400'}>{text}</div>

            <div className={'ml-2'}>{children}</div>
          </div>
        );
      },
      [jumpToHeading]
    );

    return (
      <div {...attributes} className={`outline-block relative my-2 px-1 ${className || ''}`}>
        <div ref={ref} className={'absolute left-0 top-0 select-none caret-transparent'}>
          {children}
        </div>
        <div contentEditable={false} className={`flex w-full select-none flex-col`}>
          <div className={'text-md my-2 font-bold'}>{t('document.outlineBlock.placeholder')}</div>
          {root.map(renderHeading)}
        </div>
      </div>
    );
  })
);

export default Outline;
