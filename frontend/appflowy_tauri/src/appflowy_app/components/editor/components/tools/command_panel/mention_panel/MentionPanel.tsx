import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  initialAnchorOrigin,
  initialTransformOrigin,
  PanelPopoverProps,
  PanelProps,
} from '$app/components/editor/components/tools/command_panel/Command.hooks';
import Popover from '@mui/material/Popover';

import MentionPanelContent from '$app/components/editor/components/tools/command_panel/mention_panel/MentionPanelContent';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';
import { useAppSelector } from '$app/stores/store';
import { MentionPage } from '$app/application/document/document.types';

export function MentionPanel({ anchorPosition, closePanel, searchText }: PanelProps) {
  const ref = useRef<HTMLDivElement>(null);
  const pagesMap = useAppSelector((state) => state.pages.pageMap);

  const pagesRef = useRef<MentionPage[]>([]);
  const [recentPages, setPages] = useState<MentionPage[]>([]);

  const loadPages = useCallback(async () => {
    const pages = Object.values(pagesMap);

    pagesRef.current = pages;
    setPages(pages);
  }, [pagesMap]);

  useEffect(() => {
    void loadPages();
  }, [loadPages]);

  useEffect(() => {
    if (!searchText) {
      setPages(pagesRef.current);
      return;
    }

    const filteredPages = pagesRef.current.filter((page) => {
      return page.name.toLowerCase().includes(searchText.toLowerCase());
    });

    setPages(filteredPages);
  }, [searchText]);
  const open = Boolean(anchorPosition);

  const {
    paperHeight,
    anchorPosition: newAnchorPosition,
    paperWidth,
    transformOrigin,
    anchorOrigin,
    isEntered,
  } = usePopoverAutoPosition({
    initialPaperWidth: 300,
    initialPaperHeight: 360,
    anchorPosition,
    initialTransformOrigin,
    initialAnchorOrigin,
    open,
  });

  return (
    <div ref={ref} className={'mention-panel'}>
      {open && (
        <Popover
          {...PanelPopoverProps}
          open={open && isEntered}
          anchorPosition={newAnchorPosition}
          anchorOrigin={anchorOrigin}
          transformOrigin={transformOrigin}
          onClose={() => closePanel(false)}
        >
          <MentionPanelContent width={paperWidth} maxHeight={paperHeight} closePanel={closePanel} pages={recentPages} />
        </Popover>
      )}
    </div>
  );
}

export default MentionPanel;
