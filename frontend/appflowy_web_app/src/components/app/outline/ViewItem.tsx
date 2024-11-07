import { View, ViewLayout } from '@/application/types';
import OutlineIcon from '@/components/_shared/outline/OutlineIcon';
import { ViewIcon } from '@/components/_shared/view-icon';
import { useAppViewId } from '@/components/app/app.hooks';
import { isFlagEmoji } from '@/utils/emoji';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { Tooltip } from '@mui/material';

function ViewItem ({ view, width, level = 0, renderExtra, expandIds, toggleExpand, onClickView }: {
  view: View;
  width: number;
  level?: number;
  renderExtra?: ({
    hovered,
    view,
  }: {
    hovered: boolean;
    view: View
  }) => React.ReactNode;
  expandIds: string[];
  toggleExpand: (id: string, isExpand: boolean) => void;
  onClickView?: (viewId: string) => void;
}) {
  const { t } = useTranslation();
  const selectedViewId = useAppViewId();
  const viewId = view.view_id;
  const selected = selectedViewId === viewId;

  const isExpanded = expandIds.includes(viewId);
  const [hovered, setHovered] = React.useState<boolean>(false);

  const getIcon = useCallback(() => {
    return <span className={'text-sm h-full flex items-center justify-center pl-0.5'}><OutlineIcon
      level={level}
      isExpanded={isExpanded}
      setIsExpanded={(status) => {
        toggleExpand(viewId, status);
      }}
    /></span>;
  }, [isExpanded, level, toggleExpand, viewId]);

  const renderItem = useMemo(() => {
    if (!view) return null;
    const { layout, icon } = view;

    return (
      <div
        style={{
          backgroundColor: selected ? 'var(--fill-list-hover)' : undefined,
          cursor: view.layout === ViewLayout.AIChat ? 'not-allowed' : 'pointer',
          paddingLeft: view.children?.length ? 0 : 1.125 * (level + 1) + 'em',
        }}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        onClick={() => {
          onClickView?.(viewId);
        }}
        className={
          'flex items-center my-0.5 overflow-hidden cursor-pointer min-h-[34px] w-full gap-1 rounded-[8px] py-1.5 px-0.5 text-sm hover:bg-fill-list-hover focus:outline-none'
        }
      >
        {view.children?.length ? getIcon() : null}
        <div
          className={`${icon && isFlagEmoji(icon.value) ? 'icon' : ''}`}
        >
          {icon?.value || <ViewIcon
            layout={layout}
            size={'medium'}
            className={'mr-1'}
          />}
        </div>
        <Tooltip
          title={view.name}
          disableInteractive={true}
        >
          <div
            className={'flex flex-1 overflow-hidden items-center gap-1 text-sm'}
          >
            <div className={'w-full truncate'}>{view.name || t('menuAppHeader.defaultNewPageName')}</div>
          </div>
        </Tooltip>
        {renderExtra && renderExtra({ hovered, view })}
      </div>
    );
  }, [view, selected, level, getIcon, t, renderExtra, hovered, onClickView, viewId]);

  const renderChildren = useMemo(() => {
    return <div
      className={'flex transform overflow-hidden w-full flex-col gap-2 transition-all'}
      style={{
        display: isExpanded ? 'block' : 'none',
      }}
    >{
      view?.children?.map((child) => (
        <ViewItem
          level={level + 1}
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
  }, [toggleExpand, onClickView, isExpanded, expandIds, level, renderExtra, view?.children, width]);

  return (
    <div
      style={{
        width,
      }}
      className={'flex overflow-hidden h-fit flex-col'}
    >
      {renderItem}
      {renderChildren}
    </div>
  );
}

export default ViewItem;