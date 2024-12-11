import ControlActions from '@/components/editor/components/toolbar/block-controls/ControlActions';
import { getScrollParent } from '@/components/global-comment/utils';
import React, { useCallback, useEffect, useRef } from 'react';
import { ReactEditor, useReadOnly, useSlateStatic } from 'slate-react';

function TableContainer({ blockId, readSummary, children, paddingLeft = 0 }: {
  blockId: string;
  readSummary?: boolean;
  children?: React.ReactNode;
  paddingLeft?: number;
}) {
  const readOnly = useReadOnly();
  const editor = useSlateStatic();
  const [showControl, setShowControl] = React.useState(false);
  const controlRef = useRef<HTMLDivElement>(null);
  const [width, setWidth] = React.useState<number | string | undefined>(undefined);
  const offsetLeftRef = useRef(paddingLeft);
  const calcTableWidth = useCallback((editorDom: HTMLElement, scrollContainer: HTMLElement) => {
    const scrollRect = scrollContainer.getBoundingClientRect();

    if (scrollRect.width < 768) {
      setWidth('100%');
      return;
    }

    setWidth(scrollRect.width - 196 + paddingLeft);
    const offsetLeft = editorDom.getBoundingClientRect().left - scrollRect.left;

    offsetLeftRef.current = offsetLeft + paddingLeft;
  }, [paddingLeft]);

  useEffect(() => {
    if (readSummary) return;
    const editorDom = ReactEditor.toDOMNode(editor, editor);
    const scrollContainer = getScrollParent(editorDom) as HTMLElement;

    if (!scrollContainer) return;
    calcTableWidth(editorDom, scrollContainer);
    const onResize = () => {
      calcTableWidth(editorDom, scrollContainer);
    };

    const resizeObserver = new ResizeObserver(onResize);

    resizeObserver.observe(scrollContainer);
    return () => {
      resizeObserver.disconnect();
    };
  }, [calcTableWidth, editor, readSummary]);
  const handleToggleMenu = useCallback((open: boolean) => {
    if (!open) {
      setShowControl(false);
    }
  }, []);

  return (
    <div
      draggable={false}
      onMouseEnter={() => {
        if (readOnly) return;
        setShowControl(true);
      }}
      onMouseLeave={() => {
        setShowControl(false);
      }}
      className={`relative w-full `}
      style={{
        width,
        maxWidth: width,
        flex: 'none',
        left: -offsetLeftRef.current,
      }}
    >
      <div
        ref={controlRef}
        style={{
          left: offsetLeftRef.current - 64,
          display: showControl ? 'block' : 'none',
        }}
        contentEditable={false}
        className={'absolute z-[10] w-[64px] top-2 pr-1'}
      >
        <ControlActions
          setOpenMenu={handleToggleMenu}
          blockId={blockId}
        />
      </div>
      <div
        draggable={false}
        contentEditable={readOnly ? false : undefined}
        onScroll={e => {
          const isHorizontal = e.currentTarget.scrollLeft > 0;
          const controlEl = controlRef.current;

          if (isHorizontal && controlEl) {
            controlEl.style.left = Math.max(-e.currentTarget.scrollLeft + offsetLeftRef.current - 64, -64) + 'px';
          }
        }}
        className={'h-full w-full overflow-x-auto overflow-y-hidden'}
        style={{
          paddingLeft: Math.max(offsetLeftRef.current - paddingLeft, 0) + 'px',
        }}
      >
        {children}
      </div>

    </div>
  );
}

export default TableContainer;