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
        return DiscIcon;
      case Letter.Circle:
        return CircleIcon;
      case Letter.Square:
        return SquareIcon;
    }
  }, [letter]);

  return (
    <span
      data-playwright-selected={false}
      contentEditable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} pr-1 text-xl`}
    >
      <Icon />
    </span>
  );
}
