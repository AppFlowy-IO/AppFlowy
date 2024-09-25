import { View, ViewLayout } from '@/application/types';

export function filterViews (views: View[], keyword: string): View[] {
  const filterAndFlatten = (views: View[]): View[] => {
    let result: View[] = [];

    for (const view of views) {
      if (view.name.toLowerCase().includes(keyword.toLowerCase())) {
        result.push(view);
      } else if (view.children) {
        const filteredChildren = filterAndFlatten(view.children);

        result = result.concat(filteredChildren);
      }
    }

    return result;
  };

  return filterAndFlatten(views);
}

export function findViewByLayout (views: View[], layout: ViewLayout[]): View | null {
  for (const view of views) {
    if (layout.includes(view.layout) && !view.extra?.is_space) {
      return view;
    }

    if (view.children) {
      const result = findViewByLayout(view.children, layout);

      if (result) {
        return result;
      }
    }
  }

  return null;
}

export function filterOutViewsByLayout (views: View[], layout: ViewLayout): View[] {
  const filterOut = (views: View[]): View[] => {
    const result: View[] = [];

    for (const view of views) {
      if (view.layout !== layout) {
        const newView = { ...view };

        newView.children = filterOut(view.children);
        result.push(newView);
      }

    }

    return result;
  };

  return filterOut(views);
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