import ChangeIconPopover from '@/components/_shared/view-icon/ChangeIconPopover';
import { getRangeRect } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import React, { useEffect } from 'react';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { MentionPanel } from './mention-panel';
import { SlashPanel } from './slash-panel';

function Panels () {
  const [emojiPosition, setEmojiPosition] = React.useState<{
    top: number;
    left: number
  } | null>(null);
  const showEmoji = Boolean(emojiPosition);
  const editor = useSlateStatic();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (createHotkey(HOT_KEY_NAME.POP_EMOJI_PICKER)(e)) {
        e.preventDefault();
        const rect = getRangeRect();

        if (!rect) return;
        setEmojiPosition({
          top: rect.top,
          left: rect.left,
        });
      }
    };

    const editorDom = ReactEditor.toDOMNode(editor, editor);

    editorDom.addEventListener('keydown', handleKeyDown);
    return () => {
      editorDom.removeEventListener('keydown', handleKeyDown);
    };
  }, [editor]);

  return (
    <>
      <MentionPanel />
      <SlashPanel setEmojiPosition={setEmojiPosition} />
      <ChangeIconPopover
        hideRemove
        anchorPosition={emojiPosition || undefined}
        open={showEmoji}
        onClose={() => {
          setEmojiPosition(null);
        }}
        iconEnabled={false}
        defaultType={'emoji'}
        onSelectIcon={({ value }) => {
          editor.insertText(value);
          setEmojiPosition(null);
          ReactEditor.focus(editor);
        }}
        popoverProps={{
          transformOrigin: {
            vertical: -32,
            horizontal: -8,
          },
        }}
      />
    </>
  );
}

export default Panels;