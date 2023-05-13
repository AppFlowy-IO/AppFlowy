import { MouseEventHandler, useCallback, useEffect } from 'react';
import { BaseRange, Editor, Node, Path, Range, Transforms } from 'slate';
import { EditableProps } from 'slate-react/dist/components/editable';
import { useSubscribeRangeSelection } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useAppDispatch } from '$app/stores/store';
import { rangeSelectionActions } from '$app_reducers/document/slice';
import { TextSelection } from '$app/interfaces/document';
import { ReactEditor } from 'slate-react';
import { syncRangeSelectionThunk } from '$app_reducers/document/async-actions/range_selection';
import { getCollapsedRange } from '$app/utils/document/blocks/common';
import { getEditorEndPoint, selectionIsForward } from '$app/utils/document/blocks/text/delta';

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
    const { isDragging, focus, anchor } = rangeRef.current;
    if (isDragging || anchor?.id !== focus?.id || !Range.isCollapsed(currentSelection as BaseRange)) return;

    if (!ReactEditor.isFocused(editor)) {
      ReactEditor.focus(editor);
    }
    Transforms.select(editor, currentSelection);
  }, [currentSelection, editor, rangeRef]);

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

  const onMouseDown: MouseEventHandler<HTMLDivElement> = useCallback(
    (e) => {
      const range = getCollapsedRange(id, editor.selection as TextSelection);
      dispatch(
        rangeSelectionActions.setRange({
          ...range,
          isDragging: true,
        })
      );
    },
    [dispatch, editor, id]
  );

  const onMouseMove: MouseEventHandler<HTMLDivElement> = useCallback(
    (e) => {
      if (!rangeRef.current) return;
      const { isDragging, anchor } = rangeRef.current;
      if (!isDragging || !anchor || ReactEditor.isFocused(editor)) return;
      if (anchor.id === id) {
        if (Range.isRange(anchor.selection)) {
          Transforms.select(editor, anchor.selection);
        }
      } else {
        const isForward = selectionIsForward(anchor.selection);
        if (!isForward) {
          Transforms.select(editor, getEditorEndPoint(editor));
        }
      }

      ReactEditor.focus(editor);
    },
    [editor, rangeRef]
  );

  const onMouseUp: MouseEventHandler<HTMLDivElement> = useCallback(
    (e) => {
      if (!rangeRef.current) return;
      const { isDragging } = rangeRef.current;
      if (!isDragging) return;
      dispatch(
        rangeSelectionActions.setRange({
          isDragging: false,
        })
      );
    },
    [dispatch, rangeRef]
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

  return {
    decorate,
    onMouseDown,
    onMouseMove,
    onMouseUp,
    onBlur,
    setLastActiveSelection,
  };
}
