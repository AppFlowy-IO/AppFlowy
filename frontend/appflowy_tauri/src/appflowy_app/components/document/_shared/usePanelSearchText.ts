import { useCallback, useEffect, useRef, useState } from 'react';
import Delta, { Op } from 'quill-delta';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { getDeltaText } from '$app/utils/document/delta';

export function useSubscribePanelSearchText({ blockId, open }: { blockId: string; open: boolean }) {
  const [searchText, setSearchText] = useState<string>('');
  const beforeOpenDeltaRef = useRef<Op[]>([]);
  const { delta: deltaStr } = useSubscribeNode(blockId);
  const handleSearch = useCallback((newDelta: Delta) => {
    const diff = new Delta(beforeOpenDeltaRef.current).diff(newDelta);
    const text = getDeltaText(diff);

    setSearchText(text);
  }, []);

  useEffect(() => {
    if (!open || !deltaStr) return;

    handleSearch(new Delta(JSON.parse(deltaStr)));
  }, [handleSearch, deltaStr, open]);

  useEffect(() => {
    if (!open) {
      beforeOpenDeltaRef.current = [];
      return;
    }
    if (beforeOpenDeltaRef.current.length > 0) return;

    const delta = new Delta(JSON.parse(deltaStr || "{}"));
    beforeOpenDeltaRef.current = delta.ops;
    handleSearch(delta);
  }, [deltaStr, handleSearch, open]);

  return {
    searchText,
  };
}
