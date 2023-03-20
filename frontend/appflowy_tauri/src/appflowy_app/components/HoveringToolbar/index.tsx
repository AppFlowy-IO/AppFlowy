import { useEffect, useRef } from 'react';
import { useFocused, useSlate } from 'slate-react';
import FormatButton from './FormatButton';
import Portal from './Portal';
import { calcToolbarPosition } from '@/appflowy_app/utils/slate/toolbar';

const HoveringToolbar = ({ blockId }: { blockId: string }) => {
  const editor = useSlate();
  const inFocus = useFocused();
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const position = calcToolbarPosition(editor, el, blockId);

    if (!position) {
      el.style.opacity = '0';
    } else {
      el.style.opacity = '1';
      el.style.top = position.top;
      el.style.left = position.left;
    }
  });

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
          <FormatButton key={format} format={format} icon={format} />
        ))}
      </div>
    </Portal>
  );
};

export default HoveringToolbar;
