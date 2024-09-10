import { ViewInfo } from '@/application/types';

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
