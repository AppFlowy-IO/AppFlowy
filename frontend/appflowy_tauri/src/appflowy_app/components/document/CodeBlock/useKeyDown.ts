import isHotkey from 'is-hotkey';
import { useCallback, useMemo } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { Keyboard } from '$app/constants/document/keyboard';
import { useCommonKeyEvents } from '$app/components/document/_shared/EditorHooks/useCommonKeyEvents';
import { enterActionForBlockThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useKeyDown(id: string) {
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();

  const commonKeyEvents = useCommonKeyEvents(id);
  const customEvents = useMemo(() => {
    return [
      ...commonKeyEvents,
      {
        // rewrite only shift + enter key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.SHIFT_ENTER, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          if (!controller) return;
          void dispatch(
            enterActionForBlockThunk({
              id,
              controller,
            })
          );
        },
      },
    ];
  }, [commonKeyEvents, controller, dispatch, id]);

  const onKeyDown = useCallback<React.KeyboardEventHandler<HTMLDivElement>>(
    (e) => {
      e.stopPropagation();
      const keyEvents = [...customEvents];

      keyEvents.forEach((keyEvent) => {
        // Here we check if the key event can be handled by the current key event
        if (keyEvent.canHandle(e)) {
          keyEvent.handler(e);
        }
      });
    },
    [customEvents]
  );

  return onKeyDown;
}
