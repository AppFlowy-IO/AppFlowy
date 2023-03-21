import FormatButton from './FormatButton';
import Portal from './Portal';
import { TreeNode } from '$app/block_editor/view/tree_node';
import { useHoveringToolbar } from './index.hooks';

const HoveringToolbar = ({ blockId, node }: { blockId: string; node: TreeNode }) => {
  const { inFocus, ref, editor } = useHoveringToolbar({ node });
  if (!inFocus) return null;

  return (
    <Portal blockId={blockId}>
      <div
        ref={ref}
        style={{
          opacity: 0,
        }}
        className='z-1 absolute mt-[-6px] inline-flex h-[32px] items-stretch overflow-hidden rounded-[8px] bg-[#333] p-2 leading-tight shadow-lg transition-opacity duration-700'
        onMouseDown={(e) => {
          // prevent toolbar from taking focus away from editor
          e.preventDefault();
        }}
      >
        {['bold', 'italic', 'underlined', 'strikethrough', 'code'].map((format) => (
          <FormatButton key={format} editor={editor} format={format} icon={format} />
        ))}
      </div>
    </Portal>
  );
};

export default HoveringToolbar;
