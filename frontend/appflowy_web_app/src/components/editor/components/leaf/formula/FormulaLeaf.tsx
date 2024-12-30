import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { KatexMath } from '@/components/_shared/katex-math';
import FormulaPopover from '@/components/editor/components/leaf/formula/FormulaPopover';
import { useLeafSelected } from '@/components/editor/components/leaf/leaf.hooks';
import { PopoverPosition } from '@mui/material';
import React, { Suspense, useCallback, useMemo, useRef, useState } from 'react';
import { Text, Element } from 'slate';
import { ReactEditor, useReadOnly, useSlateStatic } from 'slate-react';

function FormulaLeaf({ formula, text, children }: {
  formula: string;
  text: Text;
  children: React.ReactNode;
}) {
  const ref = useRef<HTMLSpanElement>(null);
  const editor = useSlateStatic();
  const { isSelected, isCursorBefore } = useLeafSelected(text);
  const [anchorPosition, setAnchorPosition] = useState<PopoverPosition | undefined>(undefined);
  const open = Boolean(anchorPosition);
  const readonly = useReadOnly() || editor.isElementReadOnly(text as unknown as Element);
  const className = useMemo(() => {
    const classList = ['formula-inline', 'relative', 'rounded', 'p-0.5'];

    if (readonly) {
      classList.push('cursor-default');
    } else {
      classList.push('select-none', 'cursor-pointer');
    }

    if (isSelected || open) classList.push('selected');
    return classList.join(' ');
  }, [open, readonly, isSelected]);

  const handleClose = useCallback(() => {
    window.getSelection()?.removeAllRanges();
    const path = ReactEditor.findPath(editor, text);

    editor.select(editor.end(path));
    ReactEditor.focus(editor);

    setAnchorPosition(undefined);
  }, [editor, text]);

  const openPopover = useCallback(() => {
    if (readonly) return;

    const rect = ref.current?.getBoundingClientRect();

    if (!rect) return;

    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left,
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
        style={{
          left: isCursorBefore ? 0 : 'auto',
          right: isCursorBefore ? 'auto' : 0,
          top: isCursorBefore ? 0 : 'auto',
          bottom: isCursorBefore ? 'auto' : 0,
        }}
        className={'absolute right-0 bottom-0 !text-transparent overflow-hidden'}
      >
      {children}
    </span>

      <span
        ref={ref}
        onClick={() => {
          editor.deselect();
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