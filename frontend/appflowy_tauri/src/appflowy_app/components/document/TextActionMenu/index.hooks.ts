import { useEffect, useMemo, useRef } from 'react';
import { useFocused, useSlate } from 'slate-react';
import { calcToolbarPosition } from '$app/utils/document/blocks/text/toolbar';
import { TextActionMenuProps } from '$app/interfaces/document';
import { blockConfig, defaultTextActionProps, textActionGroups } from '$app/constants/document/config';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';

export function useMenuStyle(id: string) {
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const nodeRect = document.querySelector(`[data-block-id="${id}"]`)?.getBoundingClientRect();

    if (!nodeRect) return;
    const position = calcToolbarPosition(el, nodeRect);

    if (!position) {
      el.style.opacity = '0';
      el.style.pointerEvents = 'none';
    } else {
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
      el.style.top = position.top;
      el.style.left = position.left;
    }
  });

  return {
    ref,
  };
}

export function useActionItems(id: string, props: TextActionMenuProps) {
  const { node } = useSubscribeNode(id);

  const { enabled, customItems, excludeItems } = useMemo(
    () => ({ ...defaultTextActionProps, ...blockConfig[node.type]?.textActionMenuProps, ...props }),
    [node.type, props]
  );
  const items = useMemo(() => customItems.filter((item) => !excludeItems.includes(item)), [customItems, excludeItems]);

  const groupItems = useMemo(() => {
    return textActionGroups.map((group) => {
      return group.filter((item) => items.includes(item));
    });
  }, [JSON.stringify(items)]);

  return {
    enabled,
    groupItems,
  };
}
