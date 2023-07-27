import React, { useMemo } from 'react';
import emojiData from '@emoji-mart/data';
import Picker from '@emoji-mart/react';
import { useTranslation } from 'react-i18next';
import { useAppSelector } from '$app/stores/store';
import { ThemeMode } from '$app/interfaces';

interface Props {
  onEmojiSelect: (emoji: string) => void;
}
function EmojiPickerComponent({ onEmojiSelect }: Props) {
  const { i18n } = useTranslation();
  const locale = useMemo(() => i18n.language.split('-')[0], [i18n.language]);

  const isDark = useAppSelector((state) => state.currentUser.userSetting.themeMode === ThemeMode.Dark);

  return (
    <Picker
      theme={isDark ? 'dark' : 'light'}
      searchPosition={'static'}
      locale={locale}
      autoFocus
      data={emojiData}
      onEmojiSelect={({ native }: { native: string }) => onEmojiSelect(native)}
    />
  );
}

export default EmojiPickerComponent;
