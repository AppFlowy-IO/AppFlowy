import { CoverType, ViewIconType, ViewMetaProps } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import TitleEditable from '@/components/view-meta/TitleEditable';
import ViewCover from '@/components/view-meta/ViewCover';
import { isFlagEmoji } from '@/utils/emoji';
import React, { lazy, Suspense, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

const AddIconCover = lazy(() => import('@/components/view-meta/AddIconCover'));

export function ViewMetaPreview ({
  icon,
  cover,
  name,
  extra,
  readOnly = true,
  viewId,
  updatePage,
  onEnter,
}: ViewMetaProps) {
  const [iconAnchorEl, setIconAnchorEl] = React.useState<null | HTMLElement>(null);

  const coverType = useMemo(() => {
    if (cover && [CoverType.NormalColor, CoverType.GradientColor].includes(cover.type)) {
      return 'color';
    }

    if (CoverType.BuildInImage === cover?.type) {
      return 'built_in';
    }

    if (cover && [CoverType.CustomImage, CoverType.UpsplashImage].includes(cover.type)) {
      return 'custom';
    }
  }, [cover]);

  const coverValue = useMemo(() => {
    if (coverType === 'built_in') {
      return {
        1: '/covers/m_cover_image_1.png',
        2: '/covers/m_cover_image_2.png',
        3: '/covers/m_cover_image_3.png',
        4: '/covers/m_cover_image_4.png',
        5: '/covers/m_cover_image_5.png',
        6: '/covers/m_cover_image_6.png',
      }[cover?.value as string];
    }

    return cover?.value;
  }, [coverType, cover?.value]);
  const { t } = useTranslation();

  const isFlag = useMemo(() => {
    return icon ? isFlagEmoji(icon.value) : false;
  }, [icon]);
  const [isHover, setIsHover] = React.useState(false);

  const handleUpdateIcon = React.useCallback(async (icon: { ty: ViewIconType, value: string }) => {
    if (!updatePage || !viewId) return;
    try {
      await updatePage(viewId, {
        icon,
        name: name || '',
        extra: extra || {},
      });
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    }
  }, [updatePage, viewId, name, extra]);

  const handleUpdateName = React.useCallback(async (newName: string) => {
    if (!updatePage || !viewId) return;
    try {
      if (name === newName) return;
      await updatePage(viewId, {
        icon: icon || {
          ty: ViewIconType.Emoji,
          value: '',
        },
        name: newName,
        extra: extra || {},
      });
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    }
  }, [name, updatePage, viewId, icon, extra]);

  const handleUpdateCover = React.useCallback(async (cover?: {
    type: CoverType;
    value: string;
  }) => {
    if (!updatePage || !viewId) return;
    try {
      await updatePage(viewId, {
        icon: icon || {
          ty: ViewIconType.Emoji,
          value: '',
        },
        name: name || '',
        extra: {
          ...extra,
          cover: cover,
        },
      });
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    }
  }, [extra, icon, name, updatePage, viewId]);

  return (
    <div className={'flex w-full flex-col items-center'}>
      {cover && <ViewCover
        onUpdateCover={handleUpdateCover}
        coverType={coverType}
        coverValue={coverValue}
        onRemoveCover={handleUpdateCover}
        readOnly={readOnly}
      />}
      <div
        onMouseEnter={() => setIsHover(true)}
        onMouseLeave={() => setIsHover(false)}
        className={'flex mt-2 flex-col relative'}
      >
        <div className={'relative max-sm:h-[38px] h-[52px] w-full'}>
          {isHover && !readOnly && <Suspense><AddIconCover
            hasIcon={!!icon?.value}
            hasCover={!!cover?.value}
            onUpdateIcon={handleUpdateIcon}
            onAddCover={() => {
              void handleUpdateCover({
                type: CoverType.BuildInImage,
                value: '1',
              });
            }}
            iconAnchorEl={iconAnchorEl}
            setIconAnchorEl={setIconAnchorEl}
          /></Suspense>}
        </div>
        <div

          className={`relative mb-6 max-sm:px-6 px-24 w-[988px] min-w-0 max-w-full overflow-visible`}
        >
          <h1
            className={
              'flex w-full gap-4 overflow-hidden whitespace-pre-wrap break-words break-all text-[2.25rem] font-bold max-md:text-[26px]'
            }
          >
            {icon?.value ?
              <div
                onClick={e => {
                  if (readOnly) return;
                  setIconAnchorEl(e.currentTarget);
                }}
                className={`view-icon ${readOnly ? '' : 'cursor-pointer hover:bg-fill-list-hover pb-1'} ${isFlag ? 'icon' : ''}`}
              >{icon?.value}</div> : null}
            {!readOnly ? <TitleEditable
                name={name || ''}
                onUpdateName={handleUpdateName}
                onEnter={onEnter}
              /> :
              <div
                className={'relative flex-1 cursor-text focus:outline-none empty:before:content-[attr(data-placeholder)] empty:before:text-text-placeholder'}
                data-placeholder={t('menuAppHeader.defaultNewPageName')}
                contentEditable={false}
              >
                {name}
              </div>}
          </h1>
        </div>
      </div>


    </div>
  );
}

export default ViewMetaPreview;
