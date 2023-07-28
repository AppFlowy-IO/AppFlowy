import React from 'react';
import { Box, IconButton } from '@mui/material';
import { DeleteOutlineRounded, SearchOutlined } from '@mui/icons-material';
import TextField from '@mui/material/TextField';
import Tooltip from '@mui/material/Tooltip';
import { randomEmoji } from '$app/utils/document/emoji';
import ShuffleIcon from '@mui/icons-material/Shuffle';
import Popover from '@mui/material/Popover';
import { useSelectSkinPopoverProps } from '$app/components/document/_shared/EmojiPicker/EmojiPicker.hooks';
import { useTranslation } from 'react-i18next';

const skinTones = [
  {
    value: 0,
    label: '✋',
  },
  {
    label: '✋🏻',
    value: 1,
  },
  {
    label: '✋🏼',
    value: 2,
  },
  {
    label: '✋🏽',
    value: 3,
  },
  {
    label: '✋🏾',
    value: 4,
  },
  {
    label: '✋🏿',
    value: 5,
  },
];

interface Props {
  onEmojiSelect: (emoji: string) => void;
  skin: number;
  onSkinSelect: (skin: number) => void;
  searchValue: string;
  onSearchChange: (value: string) => void;
}

function EmojiPickerHeader({ onEmojiSelect, onSkinSelect, searchValue, onSearchChange, skin }: Props) {
  const { onOpen, ...popoverProps } = useSelectSkinPopoverProps();
  const { t } = useTranslation();

  return (
    <div className={'h-[45px] px-0.5'}>
      <div className={'search-input flex items-end'}>
        <Box sx={{ display: 'flex', alignItems: 'flex-end', marginRight: 2 }}>
          <SearchOutlined sx={{ color: 'action.active', mr: 1, my: 0.5 }} />
          <TextField
            value={searchValue}
            onChange={(e) => {
              onSearchChange(e.target.value);
            }}
            label={t('search.label')}
            variant='standard'
          />
        </Box>
        <Tooltip title={t('emoji.random')}>
          <div className={'random-emoji-btn mr-2 rounded border border-line-divider'}>
            <IconButton
              onClick={() => {
                const emoji = randomEmoji();

                onEmojiSelect(emoji);
              }}
            >
              <ShuffleIcon />
            </IconButton>
          </div>
        </Tooltip>
        <Tooltip title={t('emoji.selectSkinTone')}>
          <div className={'random-emoji-btn mr-2 rounded border border-line-divider'}>
            <IconButton size={'small'} className={'h-[25px] w-[25px]'} onClick={onOpen}>
              {skinTones[skin].label}
            </IconButton>
          </div>
        </Tooltip>
        <Tooltip title={t('emoji.remove')}>
          <div className={'random-emoji-btn rounded border border-line-divider'}>
            <IconButton
              onClick={() => {
                onEmojiSelect('');
              }}
            >
              <DeleteOutlineRounded />
            </IconButton>
          </div>
        </Tooltip>
      </div>
      <Popover {...popoverProps}>
        <div className={'flex items-center p-2'}>
          {skinTones.map((skinTone) => (
            <div className={'mx-0.5'} key={skinTone.value}>
              <IconButton
                style={{
                  backgroundColor: skinTone.value === skin ? 'var(--fill-list-hover)' : 'transparent',
                }}
                size={'small'}
                onClick={() => {
                  onSkinSelect(skinTone.value);
                  popoverProps.onClose?.();
                }}
              >
                {skinTone.label}
              </IconButton>
            </div>
          ))}
        </div>
      </Popover>
    </div>
  );
}

export default EmojiPickerHeader;
