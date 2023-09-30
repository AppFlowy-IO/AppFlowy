import React, { useCallback, useState } from 'react';
import Popover from '@mui/material/Popover';
import EmojiPicker from '$app/components/_shared/EmojiPicker';
import { PageIcon } from '$app_reducers/pages/slice';

function DocumentIcon({
  icon,
  className,
  onUpdateIcon,
}: {
  icon?: PageIcon;
  className?: string;
  onUpdateIcon: (icon: string) => void;
}) {
  const [anchorPosition, setAnchorPosition] = useState<
    | undefined
    | {
        top: number;
        left: number;
      }
  >(undefined);
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
      <div className={`absolute bottom-0 left-0 pt-[20px] ${className}`}>
        <div onClick={onOpen} className={'h-full w-full cursor-pointer rounded text-6xl hover:text-7xl'}>
          {icon.value}
        </div>
      </div>
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
    </>
  );
}

export default DocumentIcon;
