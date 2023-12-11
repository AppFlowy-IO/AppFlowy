import { useCallback, useEffect, useState } from 'react';
import { Keyboard } from '$app/constants/document/keyboard';

export const useBindArrowKey = ({
  options,
  onLeft,
  onRight,
  onEnter,
  onChange,
  selectOption,
}: {
  options: string[];
  onLeft?: () => void;
  onRight?: () => void;
  onEnter?: () => void;
  onChange?: (key: string) => void;
  selectOption?: string | null;
}) => {
  const [isRun, setIsRun] = useState(false);
  const onUp = useCallback(() => {
    const getSelected = () => {
      const index = options.findIndex((item) => item === selectOption);

      if (index === -1) return options[0];
      const length = options.length;

      return options[(index + length - 1) % length];
    };

    onChange?.(getSelected());
  }, [onChange, options, selectOption]);

  const onDown = useCallback(() => {
    const getSelected = () => {
      const index = options.findIndex((item) => item === selectOption);

      if (index === -1) return options[0];
      const length = options.length;

      return options[(index + 1) % length];
    };

    onChange?.(getSelected());
  }, [onChange, options, selectOption]);

  const handleArrowKey = useCallback(
    (e: KeyboardEvent) => {
      if (
        [Keyboard.keys.UP, Keyboard.keys.DOWN, Keyboard.keys.LEFT, Keyboard.keys.RIGHT, Keyboard.keys.ENTER].includes(
          e.key
        )
      ) {
        e.stopPropagation();
        e.preventDefault();
      }

      if (e.key === Keyboard.keys.UP) {
        onUp();
      } else if (e.key === Keyboard.keys.DOWN) {
        onDown();
      } else if (e.key === Keyboard.keys.LEFT) {
        onLeft?.();
      } else if (e.key === Keyboard.keys.RIGHT) {
        onRight?.();
      } else if (e.key === Keyboard.keys.ENTER) {
        onEnter?.();
      }
    },
    [onDown, onEnter, onLeft, onRight, onUp]
  );

  const run = useCallback(() => {
    setIsRun(true);
  }, []);

  const stop = useCallback(() => {
    setIsRun(false);
  }, []);

  useEffect(() => {
    if (isRun) {
      document.addEventListener('keydown', handleArrowKey, true);
    } else {
      document.removeEventListener('keydown', handleArrowKey, true);
    }

    return () => {
      document.removeEventListener('keydown', handleArrowKey, true);
    };
  }, [handleArrowKey, isRun]);

  return {
    run,
    stop,
  };
};
