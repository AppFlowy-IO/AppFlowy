import { AlignType } from '@/application/collab.type';
import { EditorElementProps, ImageBlockNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useCallback, useMemo, useRef } from 'react';
import { ReactEditor, useSelected, useSlateStatic } from 'slate-react';
import ImageEmpty from './ImageEmpty';
import ImageRender from './ImageRender';

export const ImageBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ImageBlockNode>>(({ node, children, className, ...attributes }, ref) => {
    const selected = useSelected();
    const { url, align } = useMemo(() => node.data || {}, [node.data]);
    const containerRef = useRef<HTMLDivElement>(null);
    const editor = useSlateStatic();
    const onFocusNode = useCallback(() => {
      ReactEditor.focus(editor);
      const path = ReactEditor.findPath(editor, node);

      editor.select(path);
    }, [editor, node]);

    const alignCss = useMemo(() => {
      if (!align) return '';

      return align === AlignType.Center ? 'justify-center' : align === AlignType.Right ? 'justify-end' : 'justify-start';
    }, [align]);

    return (
      <div
        {...attributes}
        ref={containerRef}
        onClick={() => {
          if (!selected) onFocusNode();
        }}
        className={`${className || ''} image-block  relative w-full cursor-pointer py-1`}
      >
        <div ref={ref} className={'absolute  left-0 top-0 h-full w-full select-none caret-transparent'}>
          {children}
        </div>
        <div
          contentEditable={false}
          className={`flex w-full select-none ${url ? '' : 'rounded border'} ${
            selected ? 'border-fill-list-hover' : 'border-line-divider'
          } ${alignCss}`}
        >
          {url ? (
            <ImageRender selected={selected} node={node} />
          ) : (
            <ImageEmpty node={node} onEscape={onFocusNode} containerRef={containerRef} />
          )}
        </div>
      </div>
    );
  })
);

export default ImageBlock;
