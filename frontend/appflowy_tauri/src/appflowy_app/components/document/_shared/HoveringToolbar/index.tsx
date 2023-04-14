import FormatButton from './FormatButton';
import Portal from '../../BlockPortal';
import { useHoveringToolbar } from './index.hooks';

const HoveringToolbar = ({ id }: { id: string }) => {
  const { inFocus, ref, editor } = useHoveringToolbar(id);
  if (!inFocus) return null;

  return (
    <Portal blockId={id}>
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
