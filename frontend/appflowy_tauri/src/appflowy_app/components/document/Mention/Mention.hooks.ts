import { useCallback, useEffect, useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { Page } from '$app_reducers/pages/slice';

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
        return page.name.toLowerCase().includes(searchText.toLowerCase());
      });

    setRecentPages(recentPages);
  }, [pages, searchText]);

  return {
    recentPages,
  };
}
