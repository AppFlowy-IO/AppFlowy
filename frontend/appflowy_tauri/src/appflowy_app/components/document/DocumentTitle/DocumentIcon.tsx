import React, { useCallback, useState } from 'react';
import Popover from '@mui/material/Popover';
import EmojiPicker from '$app/components/document/_shared/EmojiPicker';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import { DeleteOutlineRounded } from '@mui/icons-material';

function DocumentIcon({
  icon,
  className,
  onUpdateIcon,
}: {
  icon?: string;
  className?: string;
  onUpdateIcon: (icon: string) => void;
}) {
  const { t } = useTranslation();
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

  const onRemoveIcon = useCallback(() => {
    onUpdateIcon('');
    setAnchorPosition(undefined);
  }, [onUpdateIcon]);

  if (!icon) return null;
  return (
    <>
      <div className={`absolute bottom-0 left-0 pt-[20px] ${className}`}>
        <div onClick={onOpen} className={'h-full w-full cursor-pointer rounded text-6xl hover:text-7xl'}>
          {icon}
        </div>
      </div>
      <Popover
        open={open}
        anchorReference='anchorPosition'
        anchorPosition={anchorPosition}
        onClose={() => setAnchorPosition(undefined)}
      >
        <div className={'flex items-center justify-end p-2'}>
          <Button onClick={onRemoveIcon} startIcon={<DeleteOutlineRounded />}>
            {t('document.plugins.cover.removeIcon')}
          </Button>
        </div>
        <EmojiPicker onEmojiSelect={onEmojiSelect} />
      </Popover>
    </>
  );
}

export default DocumentIcon;
