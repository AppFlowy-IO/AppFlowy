import emojiData, { EmojiMartData } from '@emoji-mart/data';

export const randomEmoji = (skin = 0) => {
  const emojis = (emojiData as EmojiMartData).emojis;
  const keys = Object.keys(emojis);
  const randomKey = keys[Math.floor(Math.random() * keys.length)];

  return emojis[randomKey].skins[skin].native;
};
