import { useAppSelector } from '$app/stores/store';
import { useMemo } from 'react';
import {
  blockConfig,
  defaultTextActionProps,
  multiLineTextActionGroups,
  multiLineTextActionProps,
  textActionGroups,
} from '$app/constants/document/config';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { TextAction } from '$app/interfaces/document';

export function useTextActionMenu() {
  const range = useAppSelector((state) => state.documentRangeSelection);

  const id = useMemo(() => {
    return range.anchor?.id === range.focus?.id ? range.anchor?.id : undefined;
  }, [range]);

  const { node } = useSubscribeNode(id || '');

  const items = useMemo(() => {
    if (node) {
      const config = blockConfig[node.type];
      const { customItems, excludeItems } = {
        ...defaultTextActionProps,
        ...config.textActionMenuProps,
      };
      return customItems?.filter((item) => !excludeItems?.includes(item)) || [];
    } else {
      return multiLineTextActionProps.customItems || [];
    }
  }, [node]);

  // the groups have default items, so we need to filter the items if this node has excluded items
  const groupItems: TextAction[][] = useMemo(() => {
    const groups = node ? textActionGroups : multiLineTextActionGroups;
    return groups.map((group) => {
      return group.filter((item) => items.includes(item));
    });
  }, [JSON.stringify(items), node]);

  return {
    groupItems,
    id,
  };
}
