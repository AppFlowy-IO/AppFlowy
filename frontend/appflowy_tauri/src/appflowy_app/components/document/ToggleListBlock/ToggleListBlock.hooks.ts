import { useAppDispatch } from '$app/stores/store';
import { useCallback } from 'react';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions/blocks/update';
import { BlockData, BlockType } from '$app/interfaces/document';
import isHotkey from 'is-hotkey';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useToggleListBlock(id: string, data: BlockData<BlockType.ToggleListBlock>) {
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();
  const toggleCollapsed = useCallback(() => {
    if (!controller) return;
    void dispatch(
      updateNodeDataThunk({
        id,
        controller,
        data: {
          collapsed: !data.collapsed,
        },
      })
    );
  }, [controller, dispatch, id, data.collapsed]);

  const handleShortcut = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      // Accepts mod for the classic "cmd on Mac, ctrl on Windows" use case.
      if (isHotkey('mod+enter', event)) {
        toggleCollapsed();
      }
    },
    [toggleCollapsed]
  );

  return {
    toggleCollapsed,
    handleShortcut,
  };
}
