import { useSelectSkinPopoverProps } from './EmojiPicker.hooks';
import React from 'react';
import { Box, IconButton } from '@mui/material';
import { Circle } from '@mui/icons-material';
import TextField from '@mui/material/TextField';
import Tooltip from '@mui/material/Tooltip';
import { randomEmoji } from '@/utils/emoji';
import { ReactComponent as ShuffleIcon } from '@/assets/shuffle.svg';
import Popover from '@mui/material/Popover';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteOutlineRounded } from '@/assets/trash.svg';
import { ReactComponent as SearchOutlined } from '@/assets/search.svg';

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
  hideRemove?: boolean;
}

function EmojiPickerHeader({ hideRemove, onEmojiSelect, onSkinSelect, searchValue, onSearchChange, skin }: Props) {
  const { onOpen, ...popoverProps } = useSelectSkinPopoverProps();
  const { t } = useTranslation();

  return (
    <div className={'px-0.5 py-2'}>
      <div className={'search-input flex items-end justify-between gap-2'}>
        <Box className={'mr-1 flex flex-1 items-center gap-2'}>
          <SearchOutlined className={'h-5 h-5'} />
          <TextField
            value={searchValue}
            onChange={(e) => {
              onSearchChange(e.target.value);
            }}
            autoFocus={true}
            fullWidth={true}
            autoCorrect={'off'}
            autoComplete={'off'}
            spellCheck={false}
            className={'search-emoji-input'}
            placeholder={t('search.label')}
            variant='standard'
          />
        </Box>
        <div className={'flex gap-1'}>
          <Tooltip title={t('emoji.random')}>
            <IconButton
              size={'small'}
              onClick={async () => {
                const emoji = await randomEmoji();

                onEmojiSelect(emoji);
              }}
            >
              <ShuffleIcon className={'h-5 h-5'} />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('emoji.selectSkinTone')}>
            <IconButton size={'small'} className={'h-[25px] w-[25px]'} onClick={onOpen}>
              <Circle
                style={{
                  fill: skinTones[skin].color,
                }}
                className={'h-5 h-5'}
              />
            </IconButton>
          </Tooltip>
          {hideRemove ? null : (
            <Tooltip title={t('emoji.remove')}>
              <IconButton
                size={'small'}
                onClick={() => {
                  onEmojiSelect('');
                }}
              >
                <DeleteOutlineRounded className={'h-5 h-5'} />
              </IconButton>
            </Tooltip>
          )}
        </div>
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
