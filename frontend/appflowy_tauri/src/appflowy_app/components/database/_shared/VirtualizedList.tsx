import { Virtualizer } from '@tanstack/react-virtual';
import React, { CSSProperties, FC } from 'react';

export interface VirtualizedListProps {
  className?: string;
  style?: CSSProperties | undefined;
  virtualizer: Virtualizer<Element, Element>,
  itemClassName?: string;
  renderItem: (index: number) => React.ReactNode;
}

export const VirtualizedList: FC<VirtualizedListProps> = ({
  className,
  style,
  itemClassName,
  virtualizer,
  renderItem,
}) => {
  const virtualItems = virtualizer.getVirtualItems();
  const { horizontal } = virtualizer.options;
  const sizeProp = horizontal ? 'width' : 'height';
  const before = virtualItems.at(0)?.start ?? 0;
  const after = virtualizer.getTotalSize() - (virtualItems.at(-1)?.end ?? 0);

  return (
    <div className={className} style={style}>
      {before > 0 && <div style={{ [sizeProp]: before }} />}
      {virtualItems.map((virtualItem) => {
        const { key, index, size } = virtualItem;

        return (
          <div
            key={key}
            className={itemClassName}
            style={{ [sizeProp]: size }}
            data-key={key}
            data-index={index}
          >
            {renderItem(index)}
          </div>
        );
      })}
      {after > 0 && <div style={{ [sizeProp]: after }} />}
    </div>
  );
};
