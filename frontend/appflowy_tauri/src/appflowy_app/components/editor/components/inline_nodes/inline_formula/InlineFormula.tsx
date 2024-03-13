import React, { forwardRef, memo, useCallback, MouseEvent, useRef, useEffect } from 'react';
import { ReactEditor, useSelected, useSlate } from 'slate-react';
import { Editor, Range, Transforms } from 'slate';
import { EditorElementProps, FormulaNode } from '$app/application/document/document.types';
import FormulaLeaf from '$app/components/editor/components/inline_nodes/inline_formula/FormulaLeaf';
import FormulaEditPopover from '$app/components/editor/components/inline_nodes/inline_formula/FormulaEditPopover';
import { getNodePath, moveCursorToNodeEnd } from '$app/components/editor/components/editor/utils';
import { CustomEditor } from '$app/components/editor/command';
import { useEditorInlineBlockState } from '$app/components/editor/stores';
import { InlineChromiumBugfix } from '$app/components/editor/components/inline_nodes/InlineChromiumBugfix';

export const InlineFormula = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<FormulaNode>>(({ node, children, ...attributes }, ref) => {
    const editor = useSlate();
    const formula = node.data;
    const { popoverOpen = false, setRange, openPopover, closePopover } = useEditorInlineBlockState('formula');
    const anchor = useRef<HTMLSpanElement | null>(null);
    const selected = useSelected();
    const open = Boolean(popoverOpen && selected);

    const isCollapsed = editor.selection && Range.isCollapsed(editor.selection);

    useEffect(() => {
      if (selected && isCollapsed && !open) {
        const afterPoint = editor.selection ? editor.after(editor.selection) : undefined;

        const afterStart = afterPoint ? Editor.start(editor, afterPoint) : undefined;

        if (afterStart) {
          editor.select(afterStart);
        }
      }
    }, [editor, isCollapsed, selected, open]);

    const handleClick = useCallback(
      (e: MouseEvent<HTMLSpanElement>) => {
        const target = e.currentTarget;
        const path = getNodePath(editor, target);

        setRange(path);
        openPopover();
      },
      [editor, openPopover, setRange]
    );

    const handleEditPopoverClose = useCallback(() => {
      closePopover();
      if (anchor.current === null) {
        return;
      }

      moveCursorToNodeEnd(editor, anchor.current);
    }, [closePopover, editor]);

    const selectNode = useCallback(() => {
      if (anchor.current === null) {
        return;
      }

      const path = getNodePath(editor, anchor.current);

      ReactEditor.focus(editor);
      Transforms.select(editor, path);
    }, [editor]);

    const onClear = useCallback(() => {
      selectNode();
      CustomEditor.toggleFormula(editor);
      closePopover();
    }, [selectNode, closePopover, editor]);

    const onDone = useCallback(
      (newFormula: string) => {
        selectNode();
        if (newFormula === '' && anchor.current) {
          const path = getNodePath(editor, anchor.current);
          const point = editor.before(path);

          CustomEditor.deleteFormula(editor);
          closePopover();
          if (point) {
            ReactEditor.focus(editor);
            editor.select(point);
          }

          return;
        } else {
          CustomEditor.updateFormula(editor, newFormula);
          handleEditPopoverClose();
        }
      },
      [closePopover, editor, handleEditPopoverClose, selectNode]
    );

    return (
      <>
        <span
          {...attributes}
          ref={(el) => {
            anchor.current = el;
            if (ref) {
              if (typeof ref === 'function') {
                ref(el);
              } else {
                ref.current = el;
              }
            }
          }}
          contentEditable={false}
          onDoubleClick={handleClick}
          onClick={handleClick}
          className={`${attributes.className ?? ''} formula-inline relative cursor-pointer rounded px-1 py-0.5 ${
            selected ? 'selected' : ''
          }`}
        >
          <InlineChromiumBugfix className={'left-0'} />
          <FormulaLeaf formula={formula}>{children}</FormulaLeaf>
          <InlineChromiumBugfix className={'right-0'} />
        </span>
        {open && (
          <FormulaEditPopover
            defaultText={formula}
            onClear={onClear}
            onDone={onDone}
            anchorEl={anchor.current}
            open={open}
            onClose={handleEditPopoverClose}
          />
        )}
      </>
    );
  })
);
