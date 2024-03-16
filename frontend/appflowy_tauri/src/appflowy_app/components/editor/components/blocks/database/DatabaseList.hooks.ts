import { useAppSelector } from '$app/stores/store';
import { ViewLayoutPB } from '@/services/backend';

export function useLoadDatabaseList({ searchText, layout }: { searchText: string; layout: ViewLayoutPB }) {
  const list = useAppSelector((state) => {
    const workspaces = state.workspace.workspaces.map((item) => item.id) ?? [];

    return Object.values(state.pages.pageMap).filter((page) => {
      if (page.layout !== layout) return false;
      const parentId = page.parentId;

      if (!parentId) return false;

      const parent = state.pages.pageMap[parentId];
      const parentLayout = parent?.layout;

      if (!workspaces.includes(parentId) && parentLayout !== ViewLayoutPB.Document) return false;

      return page.name.toLowerCase().includes(searchText.toLowerCase());
    });
  });

  return {
    list,
  };
}
