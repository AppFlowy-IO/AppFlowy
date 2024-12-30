import { QuickNote } from '@/application/types';
import dayjs from 'dayjs';

export function getTitle(note: QuickNote): string {
  let text = '';

  for (const item of note.data) {
    let itemText = '';

    item.delta.forEach((op) => {
      if (typeof op.insert === 'string') {
        itemText += op.insert;
      }
    });

    if (itemText.length > 0) {
      text += itemText;
      break;
    }
  }

  return text;
}

export function getUpdateTime(note: QuickNote): string {
  const date = dayjs(note.last_updated_at);
  const today = date.isSame(dayjs(), 'day');

  if (today) {
    return date.format('HH:mm');
  }

  return date.format('MMMM D, YYYY');
}

export function getSummary(note: QuickNote): string {
  let text = '';

  let start = false;

  for (const item of note.data) {
    let itemText = '';

    item.delta.forEach((op) => {
      if (typeof op.insert === 'string') {
        itemText += op.insert;
      }
    });

    if (itemText.length > 0) {
      if (start) {
        text += itemText;
        break;
      } else {
        start = true;
      }
    }
  }

  return text.trim();
}

export function setPopoverPosition(position: {
  expand: { x: number, y: number } | null,
  normal: { x: number, y: number } | null,
}) {
  localStorage.setItem('quick_note_popover_position', JSON.stringify(position));
}

export function getPopoverPosition(): {
  expand: { x: number, y: number } | null,
  normal: { x: number, y: number } | null,
} {
  const position = localStorage.getItem('quick_note_popover_position');

  if (position) {
    return JSON.parse(position);
  }

  return {
    expand: null,
    normal: null,
  };
}