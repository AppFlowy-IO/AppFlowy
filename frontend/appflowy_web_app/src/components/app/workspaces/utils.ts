import { Workspace } from '@/application/types';
import { getAvatar } from '@/components/_shared/view-icon/utils';

export function getAvatarProps (workspace: Workspace) {
  return getAvatar({
    icon: workspace.icon,
    name: workspace.name,
  });
}