import React, { useCallback, useState } from 'react';
import Popover from '@mui/material/Popover';
import EmojiPicker from '$app/components/_shared/emoji_picker/EmojiPicker';
import { PageIcon } from '$app_reducers/pages/slice';

function ViewIcon({ icon, onUpdateIcon }: { icon?: PageIcon; onUpdateIcon: (icon: string) => void }) {
  const [anchorPosition, setAnchorPosition] = useState<{
    top: number;
    left: number;
  }>();

  const open = Boolean(anchorPosition);
  const onOpen = useCallback((event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();

    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left,
    });
  }, []);

  const onEmojiSelect = useCallback(
    (emoji: string) => {
      onUpdateIcon(emoji);
      if (!emoji) {
        setAnchorPosition(undefined);
      }
    },
    [onUpdateIcon]
  );

  if (!icon) return null;
  return (
    <>
      <div className={`view-icon -ml-2 flex rounded p-2`}>
        <div onClick={onOpen} className={'h-full w-full cursor-pointer rounded text-6xl'}>
          {icon.value}
        </div>
      </div>
      {open && (
        <Popover
          open={open}
          autoFocus={true}
          disableRestoreFocus={false}
          anchorReference='anchorPosition'
          anchorPosition={anchorPosition}
          onClose={() => setAnchorPosition(undefined)}
        >
          <EmojiPicker
            defaultEmoji={icon.value}
            onEscape={() => {
              setAnchorPosition(undefined);
            }}
            onEmojiSelect={onEmojiSelect}
          />
        </Popover>
      )}
    </>
  );
}

export default ViewIcon;
