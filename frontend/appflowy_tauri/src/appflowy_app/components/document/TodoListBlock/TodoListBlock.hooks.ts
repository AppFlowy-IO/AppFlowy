import { useAppDispatch } from '$app/stores/store';
import { useCallback } from 'react';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions/blocks/update';
import { BlockData, BlockType } from '$app/interfaces/document';
import isHotkey from 'is-hotkey';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useTodoListBlock(id: string, data: BlockData<BlockType.TodoListBlock>) {
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();
  const toggleCheckbox = useCallback(() => {
    if (!controller) return;
    void dispatch(
      updateNodeDataThunk({
        id,
        controller,
        data: {
          checked: !data.checked,
        },
      })
    );
  }, [controller, dispatch, id, data.checked]);

  const handleShortcut = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      // Accepts mod for the classic "cmd on Mac, ctrl on Windows" use case.
      if (isHotkey('mod+enter', event)) {
        toggleCheckbox();
      }
    },
    [toggleCheckbox]
  );

  return {
    toggleCheckbox,
    handleShortcut,
  };
}
