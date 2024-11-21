import { AlignType, BlockType } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import { EditorElementProps, ImageBlockNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useCallback, useMemo, useRef, useState } from 'react';
import { ReactEditor, useReadOnly, useSelected, useSlateStatic } from 'slate-react';
import ImageEmpty from './ImageEmpty';
import ImageRender from './ImageRender';

export const ImageBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ImageBlockNode>>(({
    node,
    children,
    ...attributes
  }, ref) => {
    const { blockId, data } = node;
    const readOnly = useReadOnly();
    const selected = useSelected();
    const { url, align } = useMemo(() => data || {}, [data]);
    const containerRef = useRef<HTMLDivElement>(null);
    const editor = useSlateStatic();
    const onFocusNode = useCallback(() => {
      ReactEditor.focus(editor);
      const path = ReactEditor.findPath(editor, node);

      editor.select(path);
    }, [editor, node]);

    const className = useMemo(() => {
      const classList = ['w-full bg-bg-body py-2'];

      if (!readOnly) {
        classList.push('cursor-pointer');
      }

      if (attributes.className) {
        classList.push(attributes.className);
      }

      return classList.join(' ');
    }, [attributes.className, readOnly]);

    const alignCss = useMemo(() => {
      if (!align) return '';

      return align === AlignType.Center ? 'justify-center' : align === AlignType.Right ? 'justify-end' : 'justify-start';
    }, [align]);
    const [showToolbar, setShowToolbar] = useState(false);
    const {
      openPopover,
    } = usePopoverContext();

    const handleClick = useCallback(async () => {
      try {
        if (!url) {
          if (containerRef.current && !readOnly) {
            openPopover(blockId, BlockType.ImageBlock, containerRef.current);
          }

          return;
        }

        // eslint-disable-next-line
      } catch (e: any) {
        notify.error(e.message);
      }
    }, [url, readOnly, openPopover, blockId]);

    return (
      <div
        {...attributes}
        ref={containerRef}
        contentEditable={readOnly ? false : undefined}
        onMouseEnter={() => {
          if (!url) return;
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
        className={className}
        onClick={handleClick}
      >

        <div
          contentEditable={false}
          className={`embed-block ${alignCss} ${url ? '!bg-transparent !border-none !rounded-none' : 'p-4'}`}
        >
          {url ? (
            <ImageRender
              showToolbar={showToolbar}
              selected={selected}
              node={node}
            />
          ) : (
            <ImageEmpty
              node={node}
              onEscape={onFocusNode}
              containerRef={containerRef}
            />
          )}
        </div>
        <div
          ref={ref}
          className={'absolute left-0 top-0 h-full w-full select-none caret-transparent'}
        >
          {children}
        </div>
      </div>
    );
  }),
);

export default ImageBlock;
