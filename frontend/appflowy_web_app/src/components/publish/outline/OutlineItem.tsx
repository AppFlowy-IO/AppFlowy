import { PublishContext, usePublishContext } from '@/application/publish';
import { View } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import SpaceIcon from '@/components/publish/header/SpaceIcon';
import { renderColor } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import React, { useCallback, useContext, useEffect } from 'react';
import { ReactComponent as ChevronDownIcon } from '@/assets/chevron_down.svg';
import { useTranslation } from 'react-i18next';

function OutlineItem ({ view, level = 0, width }: { view: View; width: number; level?: number }) {
  const [isExpanded, setIsExpanded] = React.useState(() => {
    return localStorage.getItem('publish_outline_expanded_' + view.view_id) === 'true';
  });

  useEffect(() => {
    localStorage.setItem('publish_outline_expanded_' + view.view_id, isExpanded ? 'true' : 'false');
  }, [isExpanded, view.view_id]);

  const selected = usePublishContext()?.viewMeta?.view_id === view.view_id;
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
          className={'opacity-50 hover:opacity-100'}
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
        className={'opacity-50 hover:opacity-100'}
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
  const renderItem = (item: View) => {
    const { icon, layout, name, view_id, extra } = item;

    const isSpace = extra?.is_space;

    return (
      <div className={'flex h-fit my-0.5 w-full flex-col gap-2'}>
        <div
          style={{
            width,
            backgroundColor: selected ? 'var(--fill-list-hover)' : undefined,
          }}
          className={
            'flex items-center w-full gap-0.5 rounded-[8px] py-1.5 px-0.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
          }
        >
          {item.children?.length ? getIcon() : null}
          <div
            onClick={async () => {
              try {
                await navigateToView?.(view_id);
              } catch (e) {
                if (isSpace) {
                  notify.warning(t('publish.spaceHasNotBeenPublished'));
                  return;
                }

                notify.warning(t('publish.hasNotBeenPublished'));
              }
            }}
            style={{
              paddingLeft: item.children?.length ? 0 : 1.125 * (level + 1) + 'rem',
            }}
            className={'flex flex-1 cursor-pointer items-center gap-1.5 overflow-hidden'}
          >
            {isSpace && extra ?
              <span
                className={'icon h-4 w-4'}
                style={{
                  backgroundColor: extra.space_icon_color ? renderColor(extra.space_icon_color) : 'rgb(163, 74, 253)',
                  borderRadius: '4px',
                }}
              >
              <SpaceIcon
                value={extra.space_icon || ''}
                char={extra.space_icon ? undefined : name.slice(0, 1)}
              /></span> :
              <div className={`${icon && isFlagEmoji(icon.value) ? 'icon' : ''}`}>
                {icon?.value || <ViewIcon layout={layout} size={'small'} />}
              </div>
            }

            <div className={'flex-1 truncate'}>{name}</div>
          </div>
        </div>
      </div>
    );
  };

  const children = view.children || [];

  return (
    <div className={'flex h-fit w-full flex-col'}>
      {renderItem(view)}
      <div
        className={'flex transform flex-col gap-2 transition-all'}
        style={{
          display: isExpanded ? 'block' : 'none',
        }}
      >
        {children
          .map((item, index) => (
            <OutlineItem level={level + 1} width={width} key={index} view={item} />
          ))}
      </div>
    </div>
  );
}

export default OutlineItem;
