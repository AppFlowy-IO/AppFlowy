import { useState } from 'react';

export const useResizer = () => {
  const [movementX, setMovementX] = useState(0);
  const [movementY, setMovementY] = useState(0);

  const onMouseDown = () => {
    const onMouseMove = (e: MouseEvent) => {
      setMovementX(e.movementX);
      setMovementY(e.movementY);
    };

    const onMouseUp = () => {
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  };

  return {
    movementX,
    movementY,
    onMouseDown,
  };
};
