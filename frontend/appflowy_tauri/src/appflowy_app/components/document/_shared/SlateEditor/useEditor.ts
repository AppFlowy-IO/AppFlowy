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
import { focusNodeByIndex } from '$app/utils/document/node';
import { Keyboard } from '$app/constants/document/keyboard';
import Delta from 'quill-delta';
import isHotkey from 'is-hotkey';
import { useSlateYjs } from '$app/components/document/_shared/SlateEditor/useSlateYjs';

export function useEditor({
  onChange,
  onSelectionChange,
  selection,
  value: delta,
  lastSelection,
  onKeyDown,
  isCodeBlock,
}: EditorProps) {
  const editor = useSlateYjs({ delta });
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
    [delta, editor.selection, onChange, onSelectionChangeHandler]
  );

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
    // It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
  }, []);

  const decorate = useCallback(
    (entry: NodeEntry) => {
      const [node, path] = entry;
      if (!lastSelection) return [];
      const slateSelection = convertToSlateSelection(lastSelection.index, lastSelection.length, editor.children);
      if (slateSelection && !Range.isCollapsed(slateSelection as BaseRange)) {
        const intersection = Range.intersection(slateSelection, Editor.range(editor, path));

        if (!intersection) {
          return [];
        }
        const range = {
          selection_high_lighted: true,
          ...intersection,
        };

        return [range];
      }
      return [];
    },
    [editor, lastSelection]
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

  useEffect(() => {
    if (!selection || !ref.current) return;
    const slateSelection = convertToSlateSelection(selection.index, selection.length, editor.children);
    if (!slateSelection) return;
    const isFocused = ReactEditor.isFocused(editor);
    if (isFocused && JSON.stringify(slateSelection) === JSON.stringify(editor.selection)) return;
    focusNodeByIndex(ref.current, selection.index, selection.length);
    Transforms.select(editor, slateSelection);
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
  };
}
