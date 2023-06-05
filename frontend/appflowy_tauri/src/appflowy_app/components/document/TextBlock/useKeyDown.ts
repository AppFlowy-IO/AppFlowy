import { useCallback, useContext, useMemo } from 'react';
import { Keyboard } from '$app/constants/document/keyboard';
import isHotkey from 'is-hotkey';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import {
  enterActionForBlockThunk,
  tabActionForBlockThunk,
  shiftTabActionForBlockThunk,
} from '$app_reducers/document/async-actions';
import { useTurnIntoBlockEvents } from './useTurnIntoBlockEvents';
import { useCommonKeyEvents } from '../_shared/EditorHooks/useCommonKeyEvents';

export function useKeyDown(id: string) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const turnIntoEvents = useTurnIntoBlockEvents(id);
  const commonKeyEvents = useCommonKeyEvents(id);
  const interceptEvents = useMemo(() => {
    return [
      ...commonKeyEvents,
      {
        // Prevent all enter key unless it be rewritten
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return e.key === Keyboard.keys.ENTER;
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
        },
      },
      {
        // rewrite only enter key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.ENTER, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          if (!controller) return;
          dispatch(
            enterActionForBlockThunk({
              id,
              controller,
            })
          );
        },
      },
      {
        // Prevent all tab key unless it be rewritten
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return e.key === Keyboard.keys.TAB;
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
        },
      },
      {
        // rewrite only tab key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.TAB, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          if (!controller) return;
          dispatch(
            tabActionForBlockThunk({
              id,
              controller,
            })
          );
        },
      },
      {
        // rewrite only shift+tab key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.SHIFT_TAB, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          if (!controller) return;
          dispatch(
            shiftTabActionForBlockThunk({
              id,
              controller,
            })
          );
        },
      },
      ...turnIntoEvents,
    ];
  }, [commonKeyEvents, controller, dispatch, id, turnIntoEvents]);

  const onKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      e.stopPropagation();

      const filteredEvents = interceptEvents.filter((event) => event.canHandle(e));
      filteredEvents.forEach((event) => event.handler(e));
    },
    [interceptEvents]
  );

  return {
    onKeyDown,
  };
}
