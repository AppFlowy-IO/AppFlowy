import ChangeIconPopover from '@/components/_shared/view-icon/ChangeIconPopover';
import React from 'react';
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

  return (
    <>
      <MentionPanel />
      <SlashPanel setEmojiPosition={setEmojiPosition} />
      <ChangeIconPopover
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