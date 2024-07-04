import { NumberedListNode } from '@/components/editor/editor.type';
import { getListLevel, letterize, romanize } from '@/components/editor/utils/list';
import React, { useMemo } from 'react';
import { ReactEditor, useSlate, useSlateStatic } from 'slate-react';
import { Element, Path } from 'slate';

enum Letter {
  Number = 'number',
  Letter = 'letter',
  Roman = 'roman',
}

function getLetterNumber(index: number, letter: Letter) {
  if (letter === Letter.Number) {
    return index;
  } else if (letter === Letter.Letter) {
    return letterize(index);
  } else {
    return romanize(index);
  }
}

export function NumberListIcon({ block, className }: { block: NumberedListNode; className: string }) {
  const editor = useSlate();
  const staticEditor = useSlateStatic();

  const path = ReactEditor.findPath(editor, block);
  const index = useMemo(() => {
    let index = 1;

    let topNode;
    let prevPath = Path.previous(path);

    while (prevPath) {
      const prev = editor.node(prevPath);

      const prevNode = prev[0] as Element;

      if (prevNode.type === block.type) {
        index += 1;
        topNode = prevNode;
      } else {
        break;
      }

      prevPath = Path.previous(prevPath);
    }

    if (!topNode) {
      return Number(block.data?.number ?? 1);
    }

    const startIndex = (topNode as NumberedListNode).data?.number ?? 1;

    return index + Number(startIndex) - 1;
  }, [editor, block, path]);

  const letter = useMemo(() => {
    const level = getListLevel(staticEditor, block.type, path);

    if (level % 3 === 0) {
      return Letter.Number;
    } else if (level % 3 === 1) {
      return Letter.Letter;
    } else {
      return Letter.Roman;
    }
  }, [block.type, staticEditor, path]);

  const dataNumber = useMemo(() => {
    return getLetterNumber(index, letter);
  }, [index, letter]);

  return (
    <span
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      contentEditable={false}
      data-number={dataNumber}
      className={`${className} numbered-icon flex w-fit min-w-[24px] justify-center pr-1 font-medium`}
    />
  );
}
