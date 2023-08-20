import React, { useState } from 'react';

export const useResizer = (onEnd?: (final: number) => void) => {
  const [movementX, setMovementX] = useState(0);
  const [movementY, setMovementY] = useState(0);
  const [newSizeX, setNewSizeX] = useState(0);
  const [newSizeY, setNewSizeY] = useState(0);

  const onMouseDown = (e1: React.MouseEvent<HTMLElement>, initial = 0) => {
    const startX = e1.screenX;
    const startY = e1.screenY;

    setNewSizeX(initial);
    setNewSizeY(initial);

    const onMouseMove = (e2: MouseEvent) => {
      setNewSizeX(initial + e2.screenX - startX);
      setNewSizeY(initial + e2.screenY - startY);
      setMovementX(e2.movementX);
      setMovementY(e2.movementY);
    };

    const onMouseUp = (e2: MouseEvent) => {
      onEnd?.(initial + e2.screenX - startX);
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  };

  return {
    movementX,
    movementY,
    newSizeX,
    newSizeY,
    onMouseDown,
  };
};
