import SpaceIcon from '@/components/_shared/breadcrumb/SpaceIcon';
import ViewItem from '@/components/app/outline/ViewItem';
import { renderColor } from '@/utils/color';
import { Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { View } from '@/application/types';

function SpaceItem ({
  view,
  width,
  renderExtra,
  expandIds,
  toggleExpand,
  onClickView,
}: {
  view: View;
  width: number;
  expandIds: string[];
  toggleExpand: (id: string, isExpand: boolean) => void;
  renderExtra?: ({
    hovered,
    view,
  }: {
    hovered: boolean;
    view: View
  }) => React.ReactNode;
  onClickView?: (viewId: string) => void;
}) {
  const [hovered, setHovered] = React.useState<boolean>(false);
  const isExpanded = expandIds.includes(view.view_id);

  const renderItem = useMemo(() => {
    if (!view) return null;
    const extra = view?.extra;
    const name = view?.name || '';

    return (
      <div
        style={{
          width,
        }}
        onClick={() => {
          toggleExpand(view.view_id, !isExpanded);
        }}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        className={
          'flex items-center px-1 truncate cursor-pointer min-h-[34px] w-full gap-0.5 rounded-[8px] py-1.5  text-sm hover:bg-fill-list-hover focus:bg-content-blue-50 focus:outline-none'
        }
      >
        <span
          className={'icon h-5 mr-1.5 w-5'}
          style={{
            backgroundColor: extra?.space_icon_color ? renderColor(extra.space_icon_color) : 'rgb(163, 74, 253)',
            borderRadius: '4px',
          }}
        >
        <SpaceIcon
          value={extra?.space_icon || ''}
          char={extra?.space_icon ? undefined : name.slice(0, 1)}
        />
        </span>
        <Tooltip
          title={name}
          disableInteractive={true}
        >
          <div
            className={'flex flex-1 overflow-hidden items-center gap-1 text-sm'}
          >
            <div className={'w-full truncate'}>{name}</div>
          </div>
        </Tooltip>
        {renderExtra && renderExtra({ hovered, view })}
      </div>
    );
  }, [hovered, isExpanded, renderExtra, toggleExpand, view, width]);

  const renderChildren = useMemo(() => {
    return <div
      className={'flex transform flex-col gap-2 transition-all'}
      style={{
        display: isExpanded ? 'block' : 'none',
      }}
    >{
      view?.children?.map((child) => (
        <ViewItem
          key={child.view_id}
          view={child}
          width={width}
          renderExtra={renderExtra}
          expandIds={expandIds}
          toggleExpand={toggleExpand}
          onClickView={onClickView}
        />
      ))
    }</div>;
  }, [onClickView, isExpanded, view?.children, width, renderExtra, expandIds, toggleExpand]);

  return (
    <div className={'flex h-fit w-full flex-col'}>
      {renderItem}
      {renderChildren}
    </div>
  );
}

export default SpaceItem;