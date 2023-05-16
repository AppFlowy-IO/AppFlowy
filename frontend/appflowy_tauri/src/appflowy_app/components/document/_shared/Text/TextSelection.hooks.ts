import { MouseEvent, useCallback, useEffect } from 'react';
import { BaseRange, Editor, Node, Path, Range, Transforms } from 'slate';
import { EditableProps } from 'slate-react/dist/components/editable';
import { useSubscribeRangeSelection } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useAppDispatch } from '$app/stores/store';
import { TextSelection } from '$app/interfaces/document';
import { ReactEditor } from 'slate-react';
import { syncRangeSelectionThunk } from '$app_reducers/document/async-actions/range_selection';
import { getNodeEndSelection } from '$app/utils/document/blocks/text/delta';
import { slateValueToDelta } from '$app/utils/document/blocks/common';
import { isEqual } from '$app/utils/tool';

export function useTextSelections(id: string, editor: ReactEditor) {
  const { rangeRef, currentSelection } = useSubscribeRangeSelection(id);
  const dispatch = useAppDispatch();

  useEffect(() => {
    if (!rangeRef.current) return;
    if (!currentSelection) {
      ReactEditor.deselect(editor);
      ReactEditor.blur(editor);
      return;
    }

    const { isDragging, focus } = rangeRef.current;
    if (isDragging || focus?.id !== id) return;
    if (!ReactEditor.isFocused(editor)) {
      ReactEditor.focus(editor);
    }
    if (!isEqual(editor.selection, currentSelection)) {
      Transforms.select(editor, currentSelection);
    }
  }, [currentSelection, editor, id, rangeRef]);

  const decorate: EditableProps['decorate'] = useCallback(
    (entry: [Node, Path]) => {
      const [node, path] = entry;

      if (currentSelection && !Range.isCollapsed(currentSelection as BaseRange)) {
        const intersection = Range.intersection(currentSelection, Editor.range(editor, path));

        if (!intersection) {
          return [];
        }
        const range = {
          selectionHighlighted: true,
          ...intersection,
        };

        return [range];
      }
      return [];
    },
    [editor, currentSelection]
  );

  const setLastActiveSelection = useCallback(
    (lastActiveSelection: Range) => {
      const selection = lastActiveSelection as TextSelection;
      dispatch(syncRangeSelectionThunk({ id, selection }));
    },
    [dispatch, id]
  );

  const onBlur = useCallback(() => {
    ReactEditor.deselect(editor);
  }, [editor]);

  const onMouseMove = useCallback(
    (e: MouseEvent) => {
      if (!rangeRef.current) return;
      const { isDragging, isForward, anchor } = rangeRef.current;
      if (!isDragging || !anchor) return;
      if (ReactEditor.isFocused(editor)) {
        return;
      }

      if (anchor.id === id) {
        Transforms.select(editor, anchor.selection);
      } else if (!isForward) {
        const endSelection = getNodeEndSelection(slateValueToDelta(editor.children));
        Transforms.select(editor, {
          anchor: endSelection.anchor,
          focus: editor.selection?.focus || endSelection.focus,
        });
      }
      ReactEditor.focus(editor);
    },
    [editor, id, rangeRef]
  );

  return {
    decorate,
    onBlur,
    onMouseMove,
    setLastActiveSelection,
  };
}
