import { EmojiMartData } from '@emoji-mart/data';

export async function randomEmoji(skin = 0) {
  const emojiData = await loadEmojiData();
  const emojis = (emojiData as EmojiMartData).emojis;
  const keys = Object.keys(emojis);
  const randomKey = keys[Math.floor(Math.random() * keys.length)];

  return emojis[randomKey].skins[skin].native;
}

export async function loadEmojiData() {
  return import('@emoji-mart/data/sets/15/native.json');
}
