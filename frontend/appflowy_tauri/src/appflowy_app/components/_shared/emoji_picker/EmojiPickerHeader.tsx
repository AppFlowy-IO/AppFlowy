import React from 'react';
import { Box, IconButton } from '@mui/material';
import { Circle, DeleteOutlineRounded, SearchOutlined } from '@mui/icons-material';
import TextField from '@mui/material/TextField';
import Tooltip from '@mui/material/Tooltip';
import { randomEmoji } from '$app/utils/emoji';
import ShuffleIcon from '@mui/icons-material/Shuffle';
import Popover from '@mui/material/Popover';
import { useSelectSkinPopoverProps } from '$app/components/_shared/emoji_picker/EmojiPicker.hooks';
import { useTranslation } from 'react-i18next';

const skinTones = [
  {
    value: 0,
    color: '#ffc93a',
  },
  {
    color: '#ffdab7',
    value: 1,
  },
  {
    color: '#e7b98f',
    value: 2,
  },
  {
    color: '#c88c61',
    value: 3,
  },
  {
    color: '#a46134',
    value: 4,
  },
  {
    color: '#5d4437',
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
    <div className={'px-0.5 py-2'}>
      <div className={'search-input flex items-end'}>
        <Box sx={{ display: 'flex', alignItems: 'flex-end', marginRight: 2 }}>
          <SearchOutlined sx={{ color: 'action.active', mr: 1, my: 0.5 }} />
          <TextField
            value={searchValue}
            onChange={(e) => {
              onSearchChange(e.target.value);
            }}
            autoFocus={true}
            autoCorrect={'off'}
            autoComplete={'off'}
            spellCheck={false}
            className={'search-emoji-input'}
            placeholder={t('search.label')}
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
              <Circle
                style={{
                  fill: skinTones[skin].color,
                }}
              />
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
                  backgroundColor: skinTone.value === skin ? 'var(--fill-list-hover)' : undefined,
                }}
                size={'small'}
                onClick={() => {
                  onSkinSelect(skinTone.value);
                  popoverProps.onClose?.();
                }}
              >
                <Circle
                  style={{
                    fill: skinTone.color,
                  }}
                />
              </IconButton>
            </div>
          ))}
        </div>
      </Popover>
    </div>
  );
}

export default EmojiPickerHeader;
