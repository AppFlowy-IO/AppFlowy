import { useVirtualizer } from '@tanstack/react-virtual';
import { FC, RefObject, useRef } from 'react';
import { useSnapshot } from 'valtio';
import { database } from '$app/stores/database';

export const GridTable: FC<{ scrollElementRef: RefObject<HTMLElement> }> = ({
  scrollElementRef,
}) => {
  const snapshot = useSnapshot(database);
  const { rows, fields } = snapshot;

  const hScrollElement = useRef(null);

  const defaultWidth = 316;
  const defaultHeight = 41;

  const rowVirtualizer = useVirtualizer({
    getItemKey: i => rows[i].id,
    count: rows.length,
    getScrollElement: () => scrollElementRef.current,
    estimateSize: (i) => rows[i].height ?? defaultHeight,
    overscan: 5,
  });

  const columnVirtualizer = useVirtualizer({
    horizontal: true,
    count: fields.length,
    getScrollElement: () => hScrollElement.current,
    estimateSize: (i) => fields[i].width ?? defaultWidth,
    overscan: 5,
  });

  const columnItems = columnVirtualizer.getVirtualItems();

  return (
    <div className="overflow-y-hidden overflow-x-auto" ref={hScrollElement}>
      <div className='px-16'>
        <div className="grid-table-header flex">
          <div className="flex">
            {columnItems.map((virtualColumn) => (
              <div
                key={virtualColumn.key}
                style={{
                  width: `${virtualColumn.size}px`,
                }}
              >
                Column {virtualColumn.index}
              </div>
            ))}
          </div>
          <div className="flex" style={{ width: defaultWidth }}>
            + New Column
          </div>
        </div>
        <div
          style={{
            position: 'relative',
            height: `${rowVirtualizer.getTotalSize()}px`,
          }}
        >
          {rowVirtualizer.getVirtualItems().map((virtualRow) => (
            <div
              key={virtualRow.key}
              data-index={virtualRow.index}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                transform: `translateY(${virtualRow.start}px)`,
                height: `${virtualRow.size}px`,
              }}
            >
              {columnItems.map((virtualColumn) => (
                <div
                  key={virtualColumn.key}
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    transform: `translateX(${virtualColumn.start}px)`,
                    width: `${virtualColumn.size}px`,
                    height: `${virtualRow.size}px`,
                  }}
                >
                  {/* <GridCell rowId={rows[virtualRow.index].id} field={fields[virtualColumn.index]} /> */}
                  <span>Cell ({virtualRow.index},{virtualColumn.index})</span>
                </div>
              ))}
            </div>
            ))}
        </div>
        <div className="add-new-row" style={{ height: defaultHeight }}>
          <div>+ New Row</div>
        </div>
        <div className="calculate-row" style={{ height: defaultHeight }}>
          {columnItems.map((virtualColumn) => (
            <div
              key={virtualColumn.key}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                transform: `translateX(${virtualColumn.start}px)`,
                width: `${virtualColumn.size}px`,
              }}
            >
            </div>
          ))}
        </div>

      </div>
    </div>
  );
};