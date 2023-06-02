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
        className='absolute mt-[-6px] inline-flex h-[32px] min-w-[100px] items-stretch overflow-hidden rounded-[8px] bg-[#333] leading-tight shadow-lg transition-opacity duration-100'
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
    const { isDragging, focus, anchor, ranges } = state.documentRange;
    if (isDragging) return false;
    if (!focus || !anchor) return false;
    const isSameLine = anchor.id === focus.id;
    const anchorRange = ranges[anchor.id];
    if (!anchorRange) return false;
    const isCollapsed = isSameLine && anchorRange.length === 0;
    return !isCollapsed;
  });
  if (!canShow) return null;

  return <TextActionComponent container={container} />;
};

export default TextActionMenu;
