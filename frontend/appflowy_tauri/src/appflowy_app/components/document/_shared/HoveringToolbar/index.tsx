import FormatButton from './FormatButton';
<<<<<<<< HEAD:frontend/appflowy_tauri/src/appflowy_app/components/document/_shared/HoveringToolbar/index.tsx
import Portal from '../../BlockPortal';
========
import Portal from '../BlockPortal';
>>>>>>>> 341dce67d45ebe46ae55e11349a19191ac99b4cf:frontend/appflowy_tauri/src/appflowy_app/components/document/HoveringToolbar/index.tsx
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
