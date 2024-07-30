import { useSelectSkinPopoverProps } from './EmojiPicker.hooks';
import React, { useCallback } from 'react';
import { Button, OutlinedInput } from '@mui/material';

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
    icon: '👋',
  },
  {
    value: 1,
    icon: '👋🏻',
  },
  {
    value: 2,
    icon: '👋🏼',
  },
  {
    value: 3,
    icon: '👋🏽',
  },
  {
    value: 4,
    icon: '👋🏾',
  },
  {
    value: 5,
    icon: '👋🏿',
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

  const renderButton = useCallback(
    ({
      onClick,
      tooltip,
      children,
    }: {
      onClick: (e: React.MouseEvent<HTMLButtonElement>) => void;
      tooltip: string;
      children: React.ReactNode;
    }) => {
      return (
        <Tooltip title={tooltip}>
          <Button
            size={'small'}
            variant={'outlined'}
            color={'inherit'}
            className={'h-9 w-9 min-w-[36px] px-0 py-0'}
            onClick={onClick}
          >
            {children}
          </Button>
        </Tooltip>
      );
    },
    []
  );

  return (
    <div className={'px-0.5 py-2'}>
      <div className={'search-input flex items-end justify-between gap-2'}>
        <OutlinedInput
          startAdornment={<SearchOutlined className={'h-6 h-6'} />}
          value={searchValue}
          onChange={(e) => {
            onSearchChange(e.target.value);
          }}
          autoFocus={true}
          fullWidth={true}
          size={'small'}
          autoCorrect={'off'}
          autoComplete={'off'}
          spellCheck={false}
          inputProps={{
            className: 'px-2 py-1.5 text-base',
          }}
          className={'search-emoji-input'}
          placeholder={t('search.label')}
        />
        <div className={'flex items-center gap-1'}>
          {renderButton({
            onClick: async () => {
              const emoji = await randomEmoji();

              onEmojiSelect(emoji);
            },
            tooltip: t('emoji.random'),
            children: <ShuffleIcon className={'h-5 w-5'} />,
          })}

          {renderButton({
            onClick: onOpen,
            tooltip: t('emoji.selectSkinTone'),
            children: <span className={'text-xl'}>{skinTones[skin].icon}</span>,
          })}

          {hideRemove
            ? null
            : renderButton({
                onClick: () => {
                  onEmojiSelect('');
                },
                tooltip: t('emoji.remove'),
                children: <DeleteOutlineRounded className={'h-5 w-5'} />,
              })}
        </div>
      </div>
      <Popover {...popoverProps}>
        <div className={'flex items-center p-2'}>
          {skinTones.map((skinTone) => (
            <div className={'mx-0.5'} key={skinTone.value}>
              <Button
                style={{
                  backgroundColor: skinTone.value === skin ? 'var(--fill-list-hover)' : undefined,
                }}
                size={'small'}
                variant={'outlined'}
                color={'inherit'}
                className={'h-9 w-9 min-w-[36px] text-xl'}
                onClick={() => {
                  onSkinSelect(skinTone.value);
                  popoverProps.onClose?.();
                }}
              >
                {skinTone.icon}
              </Button>
            </div>
          ))}
        </div>
      </Popover>
    </div>
  );
}

export default EmojiPickerHeader;
