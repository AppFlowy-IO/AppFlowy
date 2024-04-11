import React, { useMemo } from 'react';
import { BulletedListNode } from '$app/application/document/document.types';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

enum Letter {
  Disc,
  Circle,
  Square,
}

function BulletedListIcon({ block, className }: { block: BulletedListNode; className: string }) {
  const staticEditor = useSlateStatic();
  const path = ReactEditor.findPath(staticEditor, block);

  const letter = useMemo(() => {
    const level = CustomEditor.getListLevel(staticEditor, block.type, path);

    if (level % 3 === 0) {
      return Letter.Disc;
    } else if (level % 3 === 1) {
      return Letter.Circle;
    } else {
      return Letter.Square;
    }
  }, [block.type, staticEditor, path]);

  const dataLetter = useMemo(() => {
    switch (letter) {
      case Letter.Disc:
        return '•';
      case Letter.Circle:
        return '◦';
      case Letter.Square:
        return '▪';
    }
  }, [letter]);

  return (
    <span
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      data-letter={dataLetter}
      contentEditable={false}
      className={`${className} bulleted-icon flex min-w-[24px] justify-center pr-1 font-medium`}
    />
  );
}

export default BulletedListIcon;
