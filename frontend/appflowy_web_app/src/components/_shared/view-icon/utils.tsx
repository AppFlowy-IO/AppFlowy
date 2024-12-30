import { stringAvatar } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';

export function getAvatar (item: {
  icon?: string;
  name: string;
}) {
  if (item.icon) {
    const isFlag = isFlagEmoji(item.icon);

    return {
      children: <span className={isFlag ? 'icon' : ''}> {item.icon} </span>,
      sx: {
        bgcolor: 'var(--bg-body)',
        color: 'var(--text-title)',
      },
    };
  }

  return stringAvatar(item.name || '');
}