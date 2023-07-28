import React, { useState } from 'react';

import { useLoadEmojiData } from '$app/components/_shared/EmojiPicker/EmojiPicker.hooks';

import EmojiPickerHeader from '$app/components/_shared/EmojiPicker/EmojiPickerHeader';
import EmojiPickerCategories from '$app/components/_shared/EmojiPicker/EmojiPickerCategories';

interface Props {
  onEmojiSelect: (emoji: string) => void;
}

function EmojiPickerComponent({ onEmojiSelect }: Props) {
  const [skin, setSkin] = useState(0);

  const { emojiCategories, setSearchValue, searchValue } = useLoadEmojiData({
    skin,
  });

  return (
    <div className={'emoji-picker flex h-[360px] max-h-[70vh] flex-col p-4 pt-2'}>
      <EmojiPickerHeader
        onEmojiSelect={onEmojiSelect}
        skin={skin}
        onSkinSelect={setSkin}
        searchValue={searchValue}
        onSearchChange={setSearchValue}
      />
      <EmojiPickerCategories onEmojiSelect={onEmojiSelect} emojiCategories={emojiCategories} />
    </div>
  );
}

export default EmojiPickerComponent;
