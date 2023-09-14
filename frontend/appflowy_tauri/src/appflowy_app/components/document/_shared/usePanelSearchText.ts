import { useCallback, useEffect, useRef, useState } from 'react';
import Delta, { Op } from 'quill-delta';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { getDeltaText } from '$app/utils/document/delta';

export function useSubscribePanelSearchText({ blockId, open }: { blockId: string; open: boolean }) {
  const [searchText, setSearchText] = useState<string>('');
  const beforeOpenDeltaRef = useRef<Op[]>([]);
  const { delta } = useSubscribeNode(blockId);
  const handleSearch = useCallback((newDelta: Delta) => {
    const diff = new Delta(beforeOpenDeltaRef.current).diff(newDelta);
    const text = getDeltaText(diff);

    setSearchText(text);
  }, []);

  useEffect(() => {
    if (!open || !delta) return;
    handleSearch(new Delta(JSON.parse(delta)));
  }, [handleSearch, delta, open]);

  useEffect(() => {
    if (!open) {
      beforeOpenDeltaRef.current = [];
      return;
    }

    beforeOpenDeltaRef.current = new Delta(JSON.parse(delta)).ops;
    handleSearch(new Delta(JSON.parse(delta)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  return {
    searchText,
  };
}
