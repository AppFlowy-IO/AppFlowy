import { useMenuStyle } from './index.hooks';
import { useAppSelector } from '$app/stores/store';
import TextActionMenuList from '$app/components/document/TextActionMenu/menu';
import BlockPortal from '$app/components/document/BlockPortal';
import { useContext, useMemo } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';

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
        className='absolute mt-[-6px] inline-flex h-[32px] min-w-[100px] items-stretch overflow-hidden rounded-[8px] bg-black leading-tight text-white shadow-lg transition-opacity duration-100'
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
  const controller = useContext(DocumentControllerContext);
  const docId = controller.documentId;
  const range = useAppSelector((state) => state.documentRange[docId]);
  const canShow = useMemo(() => {
    const { isDragging, focus, anchor, ranges, caret } = range;
    // don't show if dragging
    if (isDragging) return false;
    // don't show if no focus or anchor
    if (!caret) return false;
    const isSameLine = anchor?.id === focus?.id;

    // show toolbar if range has multiple nodes
    if (!isSameLine) return true;
    const caretRange = ranges[caret.id];
    // don't show if no caret range
    if (!caretRange) return false;
    // show toolbar if range is not collapsed
    return caretRange.length > 0;
  }, [range]);

  if (!canShow) return null;

  return <TextActionComponent container={container} />;
};

export default TextActionMenu;
