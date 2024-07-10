import { PublishViewInfo } from '@/application/collab.type';

export function filterViews(views: PublishViewInfo[], keyword: string): PublishViewInfo[] {
  const filterAndFlatten = (views: PublishViewInfo[]): PublishViewInfo[] => {
    let result: PublishViewInfo[] = [];

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
