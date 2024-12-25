import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { KatexMath } from '@/components/_shared/katex-math';
import FormulaPopover from '@/components/editor/components/leaf/formula/FormulaPopover';
import { useLeafSelected } from '@/components/editor/components/leaf/leaf.hooks';
import { PopoverPosition } from '@mui/material';
import React, { Suspense, useCallback, useMemo, useRef, useState } from 'react';
import { Text } from 'slate';
import { ReactEditor, useReadOnly, useSlateStatic } from 'slate-react';

function FormulaLeaf ({ formula, text }: {
  formula: string;
  text: Text;
}) {
  const ref = useRef<HTMLSpanElement>(null);
  const editor = useSlateStatic();
  const { isSelected, isCursorAfter, isCursorBefore } = useLeafSelected(text);
  const [anchorPosition, setAnchorPosition] = useState<PopoverPosition | undefined>(undefined);
  const open = Boolean(anchorPosition);
  const readonly = useReadOnly();
  const className = useMemo(() => {
    const classList = ['formula-inline', 'relative', 'rounded', 'p-0.5'];

    if (readonly) {
      classList.push('cursor-default');
    } else {
      classList.push('select-none', 'cursor-pointer');
    }

    if (isSelected || open) classList.push('selected');
    if (isCursorAfter) classList.push('cursor-after');
    if (isCursorBefore) classList.push('cursor-before');
    return classList.join(' ');
  }, [open, readonly, isSelected, isCursorAfter, isCursorBefore]);

  const handleClose = useCallback(() => {
    setAnchorPosition(undefined);
  }, []);

  const openPopover = useCallback(() => {
    if (readonly) return;
    const rect = ref.current?.getBoundingClientRect();

    if (!rect) return;

    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left + rect.width / 2,
    });
  }, [readonly]);

  const handleDone = useCallback((newFormula: string) => {
    handleClose();
    const path = ReactEditor.findPath(editor, text);

    editor.select(path);
    CustomEditor.addMark(editor, {
      key: EditorMarkFormat.Formula,
      value: newFormula,
    });
  }, [handleClose, editor, text]);

  const handleClear = useCallback(() => {
    handleClose();
    ReactEditor.focus(editor);
    const path = ReactEditor.findPath(editor, text);

    editor.select(path);

    CustomEditor.removeMark(editor, EditorMarkFormat.Formula);

    editor.delete();
    editor.insertText(formula);
  }, [editor, formula, handleClose, text]);

  return (
    <>
      <span
        ref={ref}
        onClick={e => {
          e.preventDefault();
          e.stopPropagation();
          openPopover();
        }}
        contentEditable={false}
        className={className}
      >
        <Suspense fallback={formula}>

        <KatexMath
          latex={formula || ''}
          isInline
        />
        </Suspense>
      </span>
      {
        open && <FormulaPopover
          open={open}
          anchorPosition={anchorPosition}
          onClose={handleClose}
          defaultValue={formula}
          onDone={handleDone}
          onClear={handleClear}
        />
      }
    </>

  );
}

export default FormulaLeaf;