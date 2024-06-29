import { PublishViewInfo, ViewLayout } from '@/application/collab.type';
import { PublishContext } from '@/application/publish';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import React, { useCallback, useContext } from 'react';
import { ReactComponent as ChevronDownIcon } from '@/assets/chevron_down.svg';
import { useTranslation } from 'react-i18next';

function OutlineItem({ view, level = 0, width }: { view: PublishViewInfo; width: number; level?: number }) {
  const [isExpanded, setIsExpanded] = React.useState(false);
  const getIcon = useCallback(() => {
    if (isExpanded) {
      return (
        <button
          style={{
            paddingLeft: 1.125 * level + 'rem',
          }}
          onClick={() => {
            setIsExpanded(false);
          }}
        >
          <ChevronDownIcon className={'h-4 w-4'} />
        </button>
      );
    }

    return (
      <button
        style={{
          paddingLeft: 1.125 * level + 'rem',
        }}
        onClick={() => {
          setIsExpanded(true);
        }}
      >
        <ChevronDownIcon className={'h-4 w-4 -rotate-90 transform'} />
      </button>
    );
  }, [isExpanded, level]);
  const { t } = useTranslation();

  const navigateToView = useContext(PublishContext)?.toView;
  const renderItem = (item: PublishViewInfo) => {
    const { icon, layout, name, view_id } = item;

    return (
      <div className={'flex h-fit flex-col gap-2'}>
        <div
          style={{
            width: width - 32,
          }}
          className={
            'flex items-center gap-0.5 rounded-[8px] p-1.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
          }
        >
          {item.child_views?.length ? getIcon() : null}
          <div
            onClick={async () => {
              try {
                await navigateToView?.(view_id);
              } catch (e) {
                notify.error(t('publish.hasNotBeenPublished'));
              }
            }}
            style={{
              paddingLeft: item.child_views?.length ? 0 : 1.125 * (level + 1) + 'rem',
            }}
            className={'flex flex-1 cursor-pointer items-center gap-1.5 overflow-hidden'}
          >
            <div className={'icon'}>{icon?.value || <ViewIcon layout={layout} size={'small'} />}</div>
            <div className={'flex-1 truncate'}>{name}</div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className={'flex h-fit flex-col'}>
      {renderItem(view)}
      <div
        className={'flex transform flex-col gap-2 transition-all'}
        style={{
          height: isExpanded && view.child_views?.length ? 'auto' : 0,
          opacity: isExpanded && view.child_views?.length ? 1 : 0,
        }}
      >
        {view.child_views
          ?.filter((view) => view.layout === ViewLayout.Document)
          ?.map((item, index) => (
            <OutlineItem level={level + 1} width={width} key={index} view={item} />
          ))}
      </div>
    </div>
  );
}

export default OutlineItem;
