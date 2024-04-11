import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlate } from 'slate-react';
import { MentionPage, MentionType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { KeyboardNavigationOption } from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
// import dayjs from 'dayjs';

// enum DateKey {
//   Today = 'today',
//   Tomorrow = 'tomorrow',
// }
export function useMentionPanel({
  closePanel,
  pages,
}: {
  pages: MentionPage[];
  closePanel: (deleteText?: boolean) => void;
}) {
  const { t } = useTranslation();
  const editor = useSlate();

  const onConfirm = useCallback(
    (key: string) => {
      const [, id] = key.split(',');

      closePanel(true);
      CustomEditor.insertMention(editor, {
        page_id: id,
        type: MentionType.PageRef,
      });
    },
    [closePanel, editor]
  );

  const renderPage = useCallback(
    (page: MentionPage) => {
      return {
        key: `${MentionType.PageRef},${page.id}`,
        content: (
          <div className={'flex items-center gap-2'}>
            <div className={'flex h-5 w-5 items-center justify-center'}>{page.icon?.value || <DocumentSvg />}</div>

            <div className={'flex-1'}>{page.name.trim() || t('menuAppHeader.defaultNewPageName')}</div>
          </div>
        ),
      };
    },
    [t]
  );

  // const renderDate = useCallback(() => {
  //   return [
  //     {
  //       key: DateKey.Today,
  //       content: (
  //         <div className={'px-3 pb-1 pt-2 text-xs '}>
  //           <span className={'text-text-title'}>{t('relativeDates.today')}</span> -{' '}
  //           <span className={'text-xs text-text-caption'}>{dayjs().format('MMM D, YYYY')}</span>
  //         </div>
  //       ),
  //
  //       children: [],
  //     },
  //     {
  //       key: DateKey.Tomorrow,
  //       content: (
  //         <div className={'px-3 pb-1 pt-2 text-xs '}>
  //           <span className={'text-text-title'}>{t('relativeDates.tomorrow')}</span>
  //         </div>
  //       ),
  //       children: [],
  //     },
  //   ];
  // }, [t]);

  const options: KeyboardNavigationOption<MentionType | string>[] = useMemo(() => {
    return [
      // {
      //   key: MentionType.Date,
      //   content: <div className={'px-3 pb-1 pt-2 text-sm'}>{t('editor.date')}</div>,
      //   children: renderDate(),
      // },
      {
        key: 'divider',
        content: <div className={'border-t border-line-divider'} />,
        children: [],
      },

      {
        key: MentionType.PageRef,
        content: <div className={'px-3 pb-1 pt-2 text-sm'}>{t('document.mention.page.label')}</div>,
        children:
          pages.length > 0
            ? pages.map(renderPage)
            : [
                {
                  key: 'noPage',
                  content: (
                    <div className={'px-3 pb-3 pt-2 text-xs text-text-caption'}>{t('findAndReplace.noResult')}</div>
                  ),
                  children: [],
                },
              ],
      },
    ];
  }, [pages, renderPage, t]);

  return {
    options,
    onConfirm,
  };
}
