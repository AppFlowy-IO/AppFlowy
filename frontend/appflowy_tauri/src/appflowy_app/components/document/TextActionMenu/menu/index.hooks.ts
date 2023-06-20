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
import { useSubscribeRanges } from '$app/components/document/_shared/SubscribeSelection.hooks';

export function useTextActionMenu() {
  const range = useSubscribeRanges();
  const isSingleLine = useMemo(() => {
    return range.focus?.id === range.anchor?.id;
  }, [range]);
  const focusId = range.caret?.id;

  const { node } = useSubscribeNode(focusId || '');

  const items = useMemo(() => {
    if (!node) return [];
    if (isSingleLine) {
      const config = blockConfig[node.type];
      const { customItems, excludeItems } = {
        ...defaultTextActionProps,
        ...config.textActionMenuProps,
      };
      return customItems?.filter((item) => !excludeItems?.includes(item)) || [];
    } else {
      return multiLineTextActionProps.customItems || [];
    }
  }, [isSingleLine, node]);

  // the groups have default items, so we need to filter the items if this node has excluded items
  const groupItems: TextAction[][] = useMemo(() => {
    const groups = node ? textActionGroups : multiLineTextActionGroups;
    return groups.map((group) => {
      return group.filter((item) => items.includes(item));
    });
  }, [JSON.stringify(items), node]);

  return {
    groupItems,
    isSingleLine,
    focusId,
  };
}
