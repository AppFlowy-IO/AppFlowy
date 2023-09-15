import { EditorProps } from '$app/interfaces/document';
import { useCallback, useEffect, useMemo, useRef } from 'react';
import { ReactEditor } from 'slate-react';
import { BaseRange, Editor, NodeEntry, Range, Selection, Transforms } from 'slate';
import { converToIndexLength, convertToSlateSelection, indent, outdent } from '$app/utils/document/slate_editor';
import { focusNodeByIndex } from '$app/utils/document/node';
import { Keyboard } from '$app/constants/document/keyboard';
import isHotkey from 'is-hotkey';
import { useSlateYjs } from '$app/components/document/_shared/SlateEditor/useSlateYjs';
import { openMention } from '$app_reducers/document/async-actions/mention';

const AFTER_RENDER_DELAY = 100;

export function useEditor({
  onChange,
  onSelectionChange,
  selection,
  value: delta,
  decorateSelection,
  onKeyDown,
  isCodeBlock,
  temporarySelection,
}: EditorProps) {
  const { editor } = useSlateYjs({ delta, onChange });
  const ref = useRef<HTMLDivElement | null>(null);
  const newValue = useMemo(() => [], []);
  const onSelectionChangeHandler = useCallback(
    (slateSelection: Selection) => {
      const rangeStatic = converToIndexLength(editor, slateSelection);

      onSelectionChange?.(rangeStatic, null);
    },
    [editor, onSelectionChange]
  );

  const onChangeHandler = useCallback(() => {
    onSelectionChangeHandler(editor.selection);
  }, [editor, onSelectionChangeHandler]);

  // Prevent attributes from being applied when entering text at the beginning or end of an inline block.
  // For example, when entering text before or after a mentioned page,
  // we expect plain text instead of applying mention attributes.
  // Similarly, when entering text before or after inline code,
  // we also expect plain text that is not confined within the inline code scope.
  const preventInlineBlockAttributeOverride = useCallback(() => {
    const marks = editor.getMarks();
    const markKeys = marks
      ? Object.keys(marks).filter((mark) => ['mention', 'formula', 'href', 'code'].includes(mark))
      : [];
    const currentSelection = editor.selection || [];
    let removeMark = markKeys.length > 0;
    const [_, path] = editor.node(currentSelection);

    if (removeMark) {
      const selectionStart = editor.start(currentSelection);
      const selectionEnd = editor.end(currentSelection);
      const isNodeEnd = editor.isEnd(selectionEnd, path);
      const isNodeStart = editor.isStart(selectionStart, path);

      removeMark = isNodeStart || isNodeEnd;
    }

    if (removeMark) {
      markKeys.forEach((mark) => {
        editor.removeMark(mark);
      });
    }
  }, [editor]);

  const onDOMBeforeInput = useCallback(
    (e: InputEvent) => {
      // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
      // It will cause repeated characters when inputting Chinese.
      // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
      if (e.inputType === 'insertFromComposition') {
        e.preventDefault();
      }

      preventInlineBlockAttributeOverride();
    },
    [preventInlineBlockAttributeOverride]
  );

  const getDecorateRange = useCallback(
    (
      path: number[],
      selection:
        | {
            index: number;
            length: number;
          }
        | undefined,
      value: Record<string, boolean | string | undefined>
    ) => {
      if (!selection) return null;
      const range = convertToSlateSelection(selection.index, selection.length, editor.children) as BaseRange;

      if (range && !Range.isCollapsed(range)) {
        const intersection = Range.intersection(range, Editor.range(editor, path));

        if (intersection) {
          return {
            ...intersection,
            ...value,
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
        getDecorateRange(path, decorateSelection, {
          selection_high_lighted: true,
        }),
        getDecorateRange(path, temporarySelection, {
          temporary: true,
        }),
      ].filter((range) => range !== null) as Range[];

      return ranges;
    },
    [temporarySelection, decorateSelection, getDecorateRange]
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
    if (!ref.current) return;

    const isFocused = ReactEditor.isFocused(editor);

    if (!selection) {
      isFocused && editor.deselect();
      return;
    }

    const slateSelection = convertToSlateSelection(selection.index, selection.length, editor.children);

    if (!slateSelection) return;

    const isEqual = JSON.stringify(slateSelection) === JSON.stringify(editor.selection);

    if (isFocused && isEqual) return;

    // why we didn't use slate api to change selection?
    // because the slate must be focused before change selection,
    // but then it will trigger selection change, and the selection is not what we want
    const isSuccess = focusNodeByIndex(ref.current, selection.index, selection.length);

    if (!isSuccess) {
      Transforms.select(editor, slateSelection);
    } else {
      // Fix: the slate is possible to lose focus in next tick after focusNodeByIndex
      setTimeout(() => {
        if (window.getSelection()?.type === 'None' && !editor.selection) {
          Transforms.select(editor, slateSelection);
        }
      }, AFTER_RENDER_DELAY);
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
  };
}
