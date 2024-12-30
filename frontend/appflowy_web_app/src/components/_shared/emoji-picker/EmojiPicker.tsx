import CircularProgress from '@mui/material/CircularProgress';
import React from 'react';

import { useLoadEmojiData } from './EmojiPicker.hooks';
import EmojiPickerHeader from './EmojiPickerHeader';
import EmojiPickerCategories from './EmojiPickerCategories';
import emptyImageSrc from '@/assets/images/empty.png';

interface Props {
  onEmojiSelect: (emoji: string) => void;
  onEscape?: () => void;
  defaultEmoji?: string;
  hideRemove?: boolean;
}

export function EmojiPicker ({ defaultEmoji, onEscape, ...props }: Props) {
  const { skin, onSkinChange, emojiCategories, setSearchValue, searchValue, onSelect, loading, isEmpty } =
    useLoadEmojiData(props);

  return (
    <div tabIndex={0} className={'emoji-picker flex h-[360px] max-h-[70vh] flex-col p-4 pt-2'}>
      <EmojiPickerHeader
        onEmojiSelect={onSelect}
        skin={skin}
        hideRemove={props.hideRemove}
        onSkinSelect={onSkinChange}
        searchValue={searchValue}
        onSearchChange={setSearchValue}
      />
      {loading ? (
        <div className={'flex h-full items-center justify-center'}>
          <CircularProgress />
        </div>
      ) : isEmpty ? (
        <img src={emptyImageSrc} alt={'No data found'} className={'mx-auto h-[200px]'} />
      ) : (
        <EmojiPickerCategories
          defaultEmoji={defaultEmoji}
          onEscape={onEscape}
          onEmojiSelect={onSelect}
          emojiCategories={emojiCategories}
        />
      )}
    </div>
  );
}

export default EmojiPicker;