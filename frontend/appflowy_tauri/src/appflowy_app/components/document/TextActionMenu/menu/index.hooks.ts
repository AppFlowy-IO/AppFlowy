import { useMemo } from 'react';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { BlockType, TextAction } from '$app/interfaces/document';
import { useSubscribeRanges } from '$app/components/document/_shared/SubscribeSelection.hooks';
import {
  defaultTextActionItems,
  multiLineTextActionGroups,
  multiLineTextActionProps,
  textActionGroups,
} from '$app/components/document/TextActionMenu/config';

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
      const excludeItems = node.type === BlockType.CodeBlock ? [TextAction.Code] : [];

      return defaultTextActionItems?.filter((item) => !excludeItems?.includes(item)) || [];
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
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(items), node]);

  return {
    groupItems,
    isSingleLine,
    focusId,
  };
}
