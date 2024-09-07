import { PublishContext, usePublishContext } from '@/application/publish';
import { View } from '@/application/types';
import { ViewIcon } from '@/components/_shared/view-icon';
import SpaceIcon from '@/components/publish/header/SpaceIcon';
import { renderColor } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import { Tooltip } from '@mui/material';
import React, { useCallback, useContext, useEffect } from 'react';
import { ReactComponent as ChevronDownIcon } from '@/assets/chevron_down.svg';
import { ReactComponent as PublishIcon } from '@/assets/publish.svg';
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
  const [hovered, setHovered] = React.useState(false);

  const renderItem = useCallback((item: View) => {
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
              if (isSpace || !item.is_published) {
                setIsExpanded(prev => !prev);
                return;
              }

              try {
                await navigateToView?.(view_id);
              } catch (e) {
                // do nothing
              }
            }}
            onMouseEnter={() => setHovered(true)}
            onMouseLeave={() => setHovered(false)}
            style={{
              paddingLeft: item.children?.length ? 0 : 1.125 * (level + 1) + 'rem',
            }}
            className={`flex flex-1 cursor-pointer select-none items-center gap-1.5 overflow-hidden`}
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

            <Tooltip title={name} enterDelay={1000} enterNextDelay={1000}>
              <div className={'flex-1 truncate'}>{name}</div>
            </Tooltip>
            {hovered && !item.is_published && !isSpace && (
              <Tooltip
                disableInteractive
                title={isSpace ? t('publish.spaceHasNotBeenPublished') : t('publish.hasNotBeenPublished')}
              >
                <div
                  className={'text-text-caption ml-2 mr-4 cursor-pointer hover:bg-fill-list-hover rounded h-5 w-5 flex items-center justify-center'}
                >
                  <PublishIcon className={'h-4 w-4'} />
                </div>
              </Tooltip>
            )}
          </div>
        </div>
      </div>
    );
  }, [hovered, getIcon, level, navigateToView, selected, t, width]);

  const children = view.children || [];

  if (!children.length && !view.is_published) {
    return null;
  }

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
