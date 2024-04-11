import React, { forwardRef, memo, useCallback, useMemo, useRef } from 'react';
import { EditorElementProps, ImageNode } from '$app/application/document/document.types';
import { ReactEditor, useSelected, useSlateStatic } from 'slate-react';
import ImageRender from '$app/components/editor/components/blocks/image/ImageRender';
import ImageEmpty from '$app/components/editor/components/blocks/image/ImageEmpty';

export const ImageBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ImageNode>>(({ node, children, className, ...attributes }, ref) => {
    const selected = useSelected();
    const { url, align } = useMemo(() => node.data || {}, [node.data]);
    const containerRef = useRef<HTMLDivElement>(null);
    const editor = useSlateStatic();
    const onFocusNode = useCallback(() => {
      ReactEditor.focus(editor);
      const path = ReactEditor.findPath(editor, node);

      editor.select(path);
    }, [editor, node]);

    return (
      <div
        {...attributes}
        ref={containerRef}
        onClick={() => {
          if (!selected) onFocusNode();
        }}
        className={`${className} image-block  relative w-full cursor-pointer py-1`}
      >
        <div ref={ref} className={'absolute  left-0 top-0 h-full w-full select-none caret-transparent'}>
          {children}
        </div>
        <div
          contentEditable={false}
          className={`flex w-full select-none ${url ? '' : 'rounded border'} ${
            selected ? 'border-fill-list-hover' : 'border-line-divider'
          } ${align === 'center' ? 'justify-center' : align === 'right' ? 'justify-end' : 'justify-start'}`}
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
