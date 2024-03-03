import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlate } from 'slate-react';
import { MentionPage, MentionType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { useAppSelector } from '$app/stores/store';
import { KeyboardNavigationOption } from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';

export function useMentionPanel({
  closePanel,
  searchText,
}: {
  searchText: string;
  closePanel: (deleteText?: boolean) => void;
}) {
  const { t } = useTranslation();
  const editor = useSlate();

  const pagesMap = useAppSelector((state) => state.pages.pageMap);

  const pagesRef = useRef<MentionPage[]>([]);
  const [recentPages, setPages] = useState<MentionPage[]>([]);

  const loadPages = useCallback(async () => {
    const pages = Object.values(pagesMap);

    pagesRef.current = pages;
    setPages(pages);
  }, [pagesMap]);

  useEffect(() => {
    void loadPages();
  }, [loadPages]);

  useEffect(() => {
    if (!searchText) {
      setPages(pagesRef.current);
      return;
    }

    const filteredPages = pagesRef.current.filter((page) => {
      return page.name.toLowerCase().includes(searchText.toLowerCase());
    });

    setPages(filteredPages);
  }, [searchText]);

  const onConfirm = useCallback(
    (key: string) => {
      const [, id] = key.split(',');

      closePanel(true);
      CustomEditor.insertMention(editor, {
        page: id,
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

            <div className={'flex-1'}>{page.name || t('document.title.placeholder')}</div>
          </div>
        ),
      };
    },
    [t]
  );

  const options: KeyboardNavigationOption<MentionType | string>[] = useMemo(() => {
    return [
      {
        key: MentionType.PageRef,
        content: <div className={'px-3 pb-1 pt-2 text-sm'}>{t('document.mention.page.label')}</div>,
        children: recentPages.map(renderPage),
      },
    ].filter((option) => option.children.length > 0);
  }, [recentPages, renderPage, t]);

  return {
    options,
    onConfirm,
  };
}
