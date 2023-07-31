import { useMenuStyle } from './index.hooks';
import TextActionMenuList from '$app/components/document/TextActionMenu/menu';
import BlockPortal from '$app/components/document/BlockPortal';
import { useEffect, useMemo, useState } from 'react';
import { useSubscribeRanges } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { debounce } from '$app/utils/tool';
import { getBlock } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

const TextActionComponent = ({ container }: { container: HTMLDivElement }) => {
  const { ref, id } = useMenuStyle(container);

  if (!id) return null;
  return (
    <BlockPortal blockId={id}>
      <div
        ref={ref}
        style={{
          opacity: 0,
        }}
        className='absolute mt-[-6px] inline-flex h-[32px] min-w-[100px] items-stretch overflow-hidden rounded-[8px] bg-fill-toolbar leading-tight text-content-on-fill shadow-md'
        onMouseDown={(e) => {
          // prevent toolbar from taking focus away from editor
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        <TextActionMenuList />
      </div>
    </BlockPortal>
  );
};

const TextActionMenu = ({ container }: { container: HTMLDivElement }) => {
  const range = useSubscribeRanges();
  const { docId } = useSubscribeDocument();
  const [show, setShow] = useState(false);

  const debounceShow = useMemo(() => {
    return debounce(() => {
      setShow(true);
    }, 100);
  }, []);

  const canShow = useMemo(() => {
    const { isDragging, focus, anchor, ranges, caret } = range;

    // don't show if dragging
    if (isDragging) return false;
    // don't show if no focus or anchor
    if (!caret) return false;
    if (!anchor || !focus) return false;

    const anchorNode = getBlock(docId, anchor.id);
    const focusNode = getBlock(docId, focus.id);

    // include document title
    if (!anchorNode.parent || !focusNode.parent) return false;

    const isSameLine = anchor.id === focus.id;

    // show toolbar if range has multiple nodes
    if (!isSameLine) return true;

    const caretRange = ranges?.[caret.id];

    if (!caretRange) return false;

    // show toolbar if range is not collapsed
    return caretRange.length > 0;
  }, [docId, range]);

  useEffect(() => {
    if (!canShow) {
      debounceShow.cancel();
      setShow(false);
      return;
    }

    debounceShow();
  }, [canShow, debounceShow]);

  if (!show) return null;

  return <TextActionComponent container={container} />;
};

export default TextActionMenu;
