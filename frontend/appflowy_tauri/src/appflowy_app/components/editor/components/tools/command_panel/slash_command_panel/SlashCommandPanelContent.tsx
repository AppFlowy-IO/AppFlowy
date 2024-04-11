import React, { useEffect, useRef } from 'react';
import KeyboardNavigation from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { useSlashCommandPanel } from '$app/components/editor/components/tools/command_panel/slash_command_panel/SlashCommandPanel.hooks';
import { useSlateStatic } from 'slate-react';
import { SlashOptionType } from '$app/components/editor/components/tools/command_panel/slash_command_panel/const';

const noResultBuffer = 2;

function SlashCommandPanelContent({
  closePanel,
  searchText,
  maxHeight,
  width,
}: {
  closePanel: (deleteText?: boolean) => void;
  searchText: string;
  maxHeight: number;
  width: number;
}) {
  const scrollRef = useRef<HTMLDivElement>(null);

  const { options, onConfirm } = useSlashCommandPanel({
    closePanel,
    searchText,
  });

  // Used to keep track of how many times the user has typed and not found any result
  const noResultCount = useRef(0);

  const editor = useSlateStatic();

  useEffect(() => {
    const { insertText, deleteBackward } = editor;

    editor.insertText = (text, opts) => {
      // close panel if track of no result is greater than buffer
      if (noResultCount.current >= noResultBuffer) {
        closePanel(false);
      }

      if (options.length === 0) {
        noResultCount.current += 1;
      }

      insertText(text, opts);
    };

    editor.deleteBackward = (unit) => {
      // reset no result count
      if (noResultCount.current > 0) {
        noResultCount.current -= 1;
      }

      // close panel if no text
      if (!searchText) {
        closePanel(true);
        return;
      }

      deleteBackward(unit);
    };

    return () => {
      editor.insertText = insertText;
      editor.deleteBackward = deleteBackward;
    };
  }, [closePanel, editor, searchText, options.length]);

  return (
    <div
      ref={scrollRef}
      style={{
        maxHeight,
        width,
      }}
      className={'overflow-auto overflow-x-hidden py-1'}
    >
      <KeyboardNavigation
        scrollRef={scrollRef}
        onEscape={closePanel}
        onConfirm={(key) => onConfirm(key as SlashOptionType)}
        options={options}
        disableFocus={true}
      />
    </div>
  );
}

export default SlashCommandPanelContent;
