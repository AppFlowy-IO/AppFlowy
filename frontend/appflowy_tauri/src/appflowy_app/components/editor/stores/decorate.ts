import { createContext, useCallback, useContext, useMemo } from 'react';
import { BaseRange, Editor, NodeEntry, Range } from 'slate';
import { proxySet } from 'valtio/utils';
import { useSnapshot } from 'valtio';
import { ReactEditor } from 'slate-react';

export const DecorateStateContext = createContext<
  Set<{
    range: BaseRange;
    class_name: string;
    type?: 'link';
  }>
>(new Set());
export const DecorateStateProvider = DecorateStateContext.Provider;

export function useInitialDecorateState(editor: ReactEditor) {
  const decorateState = useMemo(
    () =>
      proxySet<{
        range: BaseRange;
        class_name: string;
      }>([]),
    []
  );

  const ranges = useSnapshot(decorateState);

  const decorate = useCallback(
    ([, path]: NodeEntry): BaseRange[] => {
      const highlightRanges: (Range & {
        class_name: string;
      })[] = [];

      ranges.forEach((state) => {
        const intersection = Range.intersection(state.range, Editor.range(editor, path));

        if (intersection) {
          highlightRanges.push({
            ...intersection,
            class_name: state.class_name,
          });
        }
      });

      return highlightRanges;
    },
    [editor, ranges]
  );

  return {
    decorate,
    decorateState,
  };
}

export function useDecorateState(type?: 'link') {
  const context = useContext(DecorateStateContext);

  const state = useSnapshot(context);

  return useMemo(() => {
    return Array.from(state).find((s) => !type || s.type === type);
  }, [state, type]);
}

export function useDecorateDispatch() {
  const context = useContext(DecorateStateContext);

  const getStaticState = useCallback(() => {
    return Array.from(context)[0];
  }, [context]);

  const add = useCallback(
    (state: { range: BaseRange; class_name: string; type?: 'link' }) => {
      context.add(state);
    },
    [context]
  );

  const clear = useCallback(() => {
    context.clear();
  }, [context]);

  return {
    add,
    clear,
    getStaticState,
  };
}
