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

  const left = Math.max(offsetLeftRef.current - paddingLeft, 0);

  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  const handleHorizontalScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    const currentTarget = e.currentTarget as HTMLElement;
    const isHorizontal = currentTarget.scrollLeft > 0;
    const controlEl = controlRef.current;

    if (isHorizontal && controlEl) {
      controlEl.style.opacity = '0';

      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }

      timeoutRef.current = setTimeout(() => {
        controlEl.style.opacity = '1';
        const scrollLeft = currentTarget.scrollLeft;

        controlEl.style.left = Math.max(-scrollLeft + offsetLeftRef.current - 64, -64) + 'px';
      }, 300);
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
          left: (left - 64) + 'px',
          visibility: showControl ? 'visible' : 'hidden',
          zIndex: showControl ? 10 : -1,
          pointerEvents: showControl ? 'auto' : 'none',
        }}
        
        contentEditable={false}
        className={'absolute z-[10] w-[64px] top-2 block pr-1'}
      >
        <ControlActions
          setOpenMenu={handleToggleMenu}
          blockId={blockId}
        />
      </div>
      <div
        draggable={false}
        contentEditable={readOnly ? false : undefined}
        onScroll={handleHorizontalScroll}
        className={'h-full w-full overflow-x-auto overflow-y-hidden'}
        style={{
          paddingLeft: left + 'px',
        }}
      >
        {children}
      </div>

    </div>
  );
}

export default TableContainer;