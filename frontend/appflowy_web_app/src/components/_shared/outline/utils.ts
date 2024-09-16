import { View, ViewInfo } from '@/application/types';

export function filterViews (views: ViewInfo[], keyword: string): ViewInfo[] {
  const filterAndFlatten = (views: ViewInfo[]): ViewInfo[] => {
    let result: ViewInfo[] = [];

    for (const view of views) {
      if (view.name.toLowerCase().includes(keyword.toLowerCase())) {
        result.push(view);
      } else if (view.child_views) {
        const filteredChildren = filterAndFlatten(view.child_views);

        result = result.concat(filteredChildren);
      }
    }

    return result;
  };

  return filterAndFlatten(views);
}

export function findAncestors (data: View[], targetId: string, currentPath: View[] = []): View[] | null {
  for (const item of data) {
    const newPath = [...currentPath, item];

    if (item.view_id === targetId) {
      return newPath;
    }

    if (item.children && item.children.length > 0) {
      const result = findAncestors(item.children, targetId, newPath);

      if (result) {
        return result;
      }
    }
  }

  return null;
}

export function findView (data: View[], targetId: string): View | null {
  for (const item of data) {
    if (item.view_id === targetId) {
      return item;
    }

    if (item.children && item.children.length > 0) {
      const result = findView(item.children, targetId);

      if (result) {
        return result;
      }
    }
  }

  return null;
}