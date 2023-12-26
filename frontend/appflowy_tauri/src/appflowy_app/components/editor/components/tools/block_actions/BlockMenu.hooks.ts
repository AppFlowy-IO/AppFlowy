import { useCallback, KeyboardEvent } from 'react';

export function useBlockMenuKeyDown({ onClose }: { onClose: () => void }) {
  const onKeyDown = useCallback(
    (e: KeyboardEvent) => {
      e.preventDefault();
      e.stopPropagation();
      switch (e.key) {
        case 'Escape':
          onClose();
          break;
        case 'ArrowUp':
        case 'ArrowDown':
        case 'ArrowLeft':
        case 'ArrowRight':
          break;
        default:
          return;
      }
    },
    [onClose]
  );

  return {
    onKeyDown,
  };
}
