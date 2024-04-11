import { createContext, useCallback, useContext, useMemo } from 'react';
import { proxyMap } from 'valtio/utils';
import { useSnapshot } from 'valtio';

export const SlashStateContext = createContext<Map<string, boolean>>(new Map());
export const SlashStateProvider = SlashStateContext.Provider;

export function useInitialSlashState() {
  const state = useMemo(() => proxyMap([['open', false]]), []);

  return state;
}

export function useSlashState() {
  const context = useContext(SlashStateContext);
  const state = useSnapshot(context);
  const open = state.get('open');

  const setOpen = useCallback(
    (open: boolean) => {
      context.set('open', open);
    },
    [context]
  );

  return {
    open,
    setOpen,
  };
}
