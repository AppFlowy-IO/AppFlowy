import { BulletedListNode } from '@/components/editor/editor.type';
import { getListLevel } from '@/components/editor/utils/list';
import React, { useMemo } from 'react';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { ReactComponent as DiscIcon } from '@/assets/bulleted_list_icon_1.svg';
import { ReactComponent as CircleIcon } from '@/assets/bulleted_list_icon_2.svg';
import { ReactComponent as SquareIcon } from '@/assets/bulleted_list_icon_3.svg';

enum Letter {
  Disc,
  Circle,
  Square,
}

export function BulletedListIcon({ block, className }: { block: BulletedListNode; className: string }) {
  const staticEditor = useSlateStatic();
  const path = ReactEditor.findPath(staticEditor, block);

  const letter = useMemo(() => {
    const level = getListLevel(staticEditor, block.type, path);

    if (level % 3 === 0) {
      return Letter.Disc;
    } else if (level % 3 === 1) {
      return Letter.Circle;
    } else {
      return Letter.Square;
    }
  }, [block.type, staticEditor, path]);

  const Icon = useMemo(() => {
    switch (letter) {
      case Letter.Disc:
        return 'disc';
      case Letter.Circle:
        return 'circle';
      case Letter.Square:
        return 'square';
    }
  }, [letter]);

  return (
    // <span
    //   onMouseDown={(e) => {
    //     e.preventDefault();
    //   }}
    //   contentEditable={false}
    //   className={`${className} bulleted-icon ${dataLetter} flex min-w-[24px] justify-center pr-1 font-medium`}
    // />
    <span
      data-playwright-selected={false}
      contentEditable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} cursor-pointer pr-1 text-xl hover:text-fill-default`}
    >
      {Icon === 'disc' ? <DiscIcon /> : Icon === 'circle' ? <CircleIcon /> : <SquareIcon />}
    </span>
  );
}
