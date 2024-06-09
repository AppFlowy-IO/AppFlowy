import React, { useRef } from 'react';
import { useMentionPanel } from '$app/components/editor/components/tools/command_panel/mention_panel/MentionPanel.hooks';

import KeyboardNavigation from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { MentionPage } from '$app/application/document/document.types';

function MentionPanelContent({
  closePanel,
  pages,
  maxHeight,
  width,
}: {
  closePanel: (deleteText?: boolean) => void;
  pages: MentionPage[];
  maxHeight: number;
  width: number;
}) {
  const scrollRef = useRef<HTMLDivElement>(null);

  const { options, onConfirm } = useMentionPanel({
    closePanel,
    pages,
  });

  return (
    <div
      ref={scrollRef}
      style={{
        maxHeight,
        width,
      }}
      className={' overflow-auto overflow-x-hidden'}
    >
      <KeyboardNavigation
        scrollRef={scrollRef}
        onEscape={closePanel}
        onConfirm={onConfirm}
        options={options}
        disableFocus={true}
      />
    </div>
  );
}

export default MentionPanelContent;
