import TextActionMenuList from './menu';
import Portal from '../BlockPortal';
import { useMenuStyle, useActionItems } from './index.hooks';
import { TextActionMenuProps } from '$app/interfaces/document';
import { Editor, Range } from 'slate';
import { useAppSelector } from '$app/stores/store';
import { useFocused, useSlate } from 'slate-react';
const TextActionMenu = ({ id, ...rest }: { id: string } & TextActionMenuProps) => {
  const editor = useSlate();
  const inFocus = useFocused();
  const { ref } = useMenuStyle(id);

  const { enabled, groupItems } = useActionItems(id, rest);
  const isDragging = useAppSelector((state) => state.documentRangeSelection.isDragging);

  const { selection } = editor;

  // Don't render if:
  // - dragging
  // - not enabled
  // - not in focus
  // - no selection
  // - selection is collapsed
  // - selection is empty
  if (
    isDragging ||
    !enabled ||
    !inFocus ||
    !selection ||
    Range.isCollapsed(selection) ||
    Editor.string(editor, selection) === ''
  )
    return null;

  return (
    <Portal blockId={id}>
      <div
        ref={ref}
        style={{
          opacity: 0,
        }}
        className='absolute mt-[-6px] inline-flex h-[32px] items-stretch overflow-hidden rounded-[8px] bg-[#333] leading-tight shadow-lg transition-opacity duration-700'
        onMouseDown={(e) => {
          // prevent toolbar from taking focus away from editor
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        <TextActionMenuList id={id} groupItems={groupItems} editor={editor} />
      </div>
    </Portal>
  );
};

export default TextActionMenu;
