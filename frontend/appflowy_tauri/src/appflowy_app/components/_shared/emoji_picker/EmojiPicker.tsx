import React from 'react';

import { useLoadEmojiData } from './EmojiPicker.hooks';
import EmojiPickerHeader from './EmojiPickerHeader';
import EmojiPickerCategories from './EmojiPickerCategories';

interface Props {
  onEmojiSelect: (emoji: string) => void;
  onEscape?: () => void;
  defaultEmoji?: string;
}

function EmojiPicker({ defaultEmoji, onEscape, ...props }: Props) {
  const { skin, onSkinChange, emojiCategories, setSearchValue, searchValue, onSelect } = useLoadEmojiData(props);

  return (
    <div tabIndex={0} className={'emoji-picker flex h-[360px] max-h-[70vh] flex-col p-4 pt-2'}>
      <EmojiPickerHeader
        onEmojiSelect={onSelect}
        skin={skin}
        onSkinSelect={onSkinChange}
        searchValue={searchValue}
        onSearchChange={setSearchValue}
      />
      <EmojiPickerCategories
        defaultEmoji={defaultEmoji}
        onEscape={onEscape}
        onEmojiSelect={onSelect}
        emojiCategories={emojiCategories}
      />
    </div>
  );
}

export default EmojiPicker;
