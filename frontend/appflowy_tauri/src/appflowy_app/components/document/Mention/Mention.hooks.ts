import { useCallback, useEffect, useRef, useState } from 'react';
import Delta, { Op } from 'quill-delta';
import { getDeltaText } from '$app/utils/document/delta';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useAppSelector } from '$app/stores/store';
import { Page } from '$app_reducers/pages/slice';

export function useSubscribeMentionSearchText({ blockId, open }: { blockId: string; open: boolean }) {
  const [searchText, setSearchText] = useState<string>('');
  const beforeOpenDeltaRef = useRef<Op[]>([]);
  const { node } = useSubscribeNode(blockId);
  const handleSearch = useCallback((newDelta: Delta) => {
    const diff = new Delta(beforeOpenDeltaRef.current).diff(newDelta);
    const text = getDeltaText(diff);

    setSearchText(text);
  }, []);

  useEffect(() => {
    if (!open) return;
    handleSearch(new Delta(node?.data?.delta));
  }, [handleSearch, node?.data?.delta, open]);

  useEffect(() => {
    if (!open) return;
    beforeOpenDeltaRef.current = node?.data?.delta;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  return {
    searchText,
  };
}
export function useMentionPopoverProps({ open }: { open: boolean }) {
  const [anchorPosition, setAnchorPosition] = useState<
    | {
        top: number;
        left: number;
      }
    | undefined
  >(undefined);
  const popoverOpen = Boolean(anchorPosition);
  const getPosition = useCallback(() => {
    const range = document.getSelection()?.getRangeAt(0);
    const rangeRect = range?.getBoundingClientRect();
    return rangeRect;
  }, []);

  useEffect(() => {
    if (open) {
      const position = getPosition();
      if (!position) return;
      setAnchorPosition({
        top: position.top + position.height || 0,
        left: position.left + 14 || 0,
      });
    } else {
      setAnchorPosition(undefined);
    }
  }, [getPosition, open]);

  return {
    anchorPosition,
    popoverOpen,
  };
}

export function useLoadRecentPages(searchText: string) {
  const [recentPages, setRecentPages] = useState<Page[]>([]);
  const pages = useAppSelector((state) => state.pages.pageMap);

  useEffect(() => {
    const recentPages = Object.values(pages)
      .map((page) => {
        return page;
      })
      .filter((page) => {
        const text = searchText.slice(1, searchText.length);
        if (!text) return true;
        return page.name.toLowerCase().includes(text.toLowerCase());
      });
    setRecentPages(recentPages);
  }, [pages, searchText]);

  return {
    recentPages,
  };
}
