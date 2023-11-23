import React, { useCallback, useState } from 'react';
import Popover from '@mui/material/Popover';
import EmojiPicker from '$app/components/_shared/EmojiPicker';
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
      setAnchorPosition(undefined);
    },
    [onUpdateIcon]
  );

  if (!icon) return null;
  return (
    <>
      <div className={`-ml-2 flex rounded p-2 hover:bg-content-blue-50`}>
        <div onClick={onOpen} className={'h-full w-full cursor-pointer rounded text-6xl'}>
          {icon.value}
        </div>
      </div>
      {open && (
        <Popover
          open={open}
          anchorReference='anchorPosition'
          anchorPosition={anchorPosition}
          disableAutoFocus
          disableRestoreFocus
          onClose={() => setAnchorPosition(undefined)}
        >
          <EmojiPicker onEmojiSelect={onEmojiSelect} />
        </Popover>
      )}
    </>
  );
}

export default ViewIcon;
