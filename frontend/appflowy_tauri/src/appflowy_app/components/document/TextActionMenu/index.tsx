import { useMenuStyle } from './index.hooks';
import { useAppSelector } from '$app/stores/store';
import { isEqual } from '$app/utils/tool';
import TextActionMenuList from '$app/components/document/TextActionMenu/menu';

const TextActionComponent = ({ container }: { container: HTMLDivElement }) => {
  const { ref } = useMenuStyle(container);

  return (
    <div
      ref={ref}
      style={{
        opacity: 0,
      }}
      className='absolute mt-[-6px] inline-flex h-[32px] min-w-[100px] items-stretch overflow-hidden rounded-[8px] bg-[#333] leading-tight shadow-lg transition-opacity duration-200'
      onMouseDown={(e) => {
        // prevent toolbar from taking focus away from editor
        e.preventDefault();
        e.stopPropagation();
      }}
    >
      <TextActionMenuList />
    </div>
  );
};
const TextActionMenu = ({ container }: { container: HTMLDivElement }) => {
  const canShow = useAppSelector((state) => {
    const range = state.documentRangeSelection;
    if (range.isDragging) return false;
    const anchorNode = range.anchor;
    const focusNode = range.focus;
    if (!anchorNode || !focusNode) return false;
    const isSameLine = anchorNode.id === focusNode.id;
    const isCollapsed = isEqual(anchorNode.selection.anchor, anchorNode.selection.focus);
    return !(isSameLine && isCollapsed);
  });
  if (!canShow) return null;

  return (
    <div className='appflowy-block-toolbar-overlay pointer-events-none fixed inset-0 overflow-hidden'>
      <TextActionComponent container={container} />
    </div>
  );
};

export default TextActionMenu;
