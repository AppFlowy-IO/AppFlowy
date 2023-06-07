import { useMenuStyle } from './index.hooks';
import { useAppSelector } from '$app/stores/store';
import TextActionMenuList from '$app/components/document/TextActionMenu/menu';
import BlockPortal from '$app/components/document/BlockPortal';

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
  const canShow = useAppSelector((state) => {
    const { isDragging, focus, anchor, ranges, caret } = state.documentRange;
    // prevent showing link popover when dragging
    if (isDragging) return false;
    // prevent showing link popover when there is no selection
    if (!focus || !anchor || !caret) return false;
    // prevent showing link popover when selection is collapsed
    const isSameLine = anchor.id === focus.id;
    const anchorRange = ranges[anchor.id];
    if (!anchorRange) return false;
    if (!isSameLine) return true;
    return anchorRange.length > 0;
  });
  if (!canShow) return null;

  return <TextActionComponent container={container} />;
};

export default TextActionMenu;
