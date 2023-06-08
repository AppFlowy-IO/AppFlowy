import { EditorProps } from '$app/interfaces/document';
import { useCallback, useEffect, useMemo, useRef } from 'react';
import { ReactEditor } from 'slate-react';
import { BaseRange, Descendant, Editor, NodeEntry, Range, Selection, Transforms } from 'slate';
import {
  converToIndexLength,
  convertToDelta,
  convertToSlateSelection,
  indent,
  outdent,
} from '$app/utils/document/slate_editor';
import { focusNodeByIndex, getWordIndices } from '$app/utils/document/node';
import { Keyboard } from '$app/constants/document/keyboard';
import Delta from 'quill-delta';
import isHotkey from 'is-hotkey';
import { useSlateYjs } from '$app/components/document/_shared/SlateEditor/useSlateYjs';

export function useEditor({
  onChange,
  onSelectionChange,
  selection,
  value: delta,
  decorateSelection,
  onKeyDown,
  isCodeBlock,
  linkDecorateSelection,
}: EditorProps) {
  const { editor } = useSlateYjs({ delta });
  const ref = useRef<HTMLDivElement | null>(null);
  const newValue = useMemo(() => [], []);
  const onSelectionChangeHandler = useCallback(
    (slateSelection: Selection) => {
      const rangeStatic = converToIndexLength(editor, slateSelection);
      onSelectionChange?.(rangeStatic, null);
    },
    [editor, onSelectionChange]
  );

  const onChangeHandler = useCallback(
    (slateValue: Descendant[]) => {
      const oldContents = delta || new Delta();
      onChange?.(convertToDelta(slateValue), oldContents);
      onSelectionChangeHandler(editor.selection);
    },
    [delta, editor, onChange, onSelectionChangeHandler]
  );

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
    // It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
  }, []);

  const getDecorateRange = useCallback(
    (
      path: number[],
      selection:
        | {
            index: number;
            length: number;
          }
        | undefined,
      key: string
    ) => {
      if (!selection) return null;
      const range = convertToSlateSelection(selection.index, selection.length, editor.children) as BaseRange;
      if (range && !Range.isCollapsed(range)) {
        const intersection = Range.intersection(range, Editor.range(editor, path));
        if (intersection) {
          return {
            [key]: true,
            ...intersection,
          };
        }
      }
      return null;
    },
    [editor]
  );

  const decorate = useCallback(
    (entry: NodeEntry) => {
      const [node, path] = entry;

      const ranges: Range[] = [
        getDecorateRange(path, decorateSelection, 'selection_high_lighted'),
        getDecorateRange(path, linkDecorateSelection, 'link_selection_lighted'),
      ].filter((range) => range !== null) as Range[];

      return ranges;
    },
    [decorateSelection, linkDecorateSelection, getDecorateRange]
  );

  const onKeyDownRewrite = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      onKeyDown?.(event);
      const insertBreak = () => {
        event.preventDefault();
        editor.insertText('\n');
      };
      // There is different behavior for code block and normal text
      // In code block, we press enter to insert a new line
      // In normal text, we press shift + enter to insert a new line
      if (isCodeBlock) {
        if (isHotkey(Keyboard.keys.ENTER, event)) {
          insertBreak();
          return;
        }
        if (isHotkey(Keyboard.keys.TAB, event)) {
          event.preventDefault();
          indent(editor, 2);
          return;
        }
        if (isHotkey(Keyboard.keys.SHIFT_TAB, event)) {
          event.preventDefault();
          outdent(editor, 2);
          return;
        }
      } else if (isHotkey(Keyboard.keys.SHIFT_ENTER, event)) {
        insertBreak();
      }
    },
    [editor, onKeyDown, isCodeBlock]
  );

  const onBlur = useCallback(
    (_event: React.FocusEvent<HTMLDivElement>) => {
      editor.deselect();
    },
    [editor]
  );

  // This is a hack to fix the bug that the editor decoration is updated cause selection is lost
  const onMouseDownCapture = useCallback(
    (event: React.MouseEvent) => {
      editor.deselect();
      requestAnimationFrame(() => {
        const range = document.caretRangeFromPoint(event.clientX, event.clientY);
        if (!range) return;
        const selection = window.getSelection();
        if (!selection) return;
        selection.removeAllRanges();
        selection.addRange(range);
      });
    },
    [editor]
  );

  // double click to select a word
  // This is a hack to fix the bug that mouse down event deselect the selection
  const onDoubleClick = useCallback((event: React.MouseEvent) => {
    const selection = window.getSelection();
    if (!selection) return;
    const range = selection.rangeCount > 0 ? selection.getRangeAt(0) : null;
    if (!range) return;
    const node = range.startContainer;
    const offset = range.startOffset;
    const wordIndices = getWordIndices(node, offset);
    if (wordIndices.length === 0) return;
    range.setStart(node, wordIndices[0].startIndex);
    range.setEnd(node, wordIndices[0].endIndex);
    selection.removeAllRanges();
    selection.addRange(range);
  }, []);

  useEffect(() => {
    if (!ref.current) return;
    const isFocused = ReactEditor.isFocused(editor);
    if (!selection) {
      isFocused && editor.deselect();
      return;
    }
    const slateSelection = convertToSlateSelection(selection.index, selection.length, editor.children);
    if (!slateSelection) return;
    if (isFocused && JSON.stringify(slateSelection) === JSON.stringify(editor.selection)) return;
    const isSuccess = focusNodeByIndex(ref.current, selection.index, selection.length);
    if (!isSuccess) {
      Transforms.select(editor, slateSelection);
    }
  }, [editor, selection]);

  return {
    editor,
    value: newValue,
    onChange: onChangeHandler,
    onDOMBeforeInput,
    decorate,
    ref,
    onKeyDown: onKeyDownRewrite,
    onBlur,
    onMouseDownCapture,
    onDoubleClick,
  };
}
