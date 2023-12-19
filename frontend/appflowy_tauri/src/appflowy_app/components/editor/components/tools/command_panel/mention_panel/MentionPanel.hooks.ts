import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlate } from 'slate-react';
import { Mention, MentionPage, MentionType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { useAppSelector } from '$app/stores/store';

export function useMentionPanel({
  closePanel,
  searchText,
}: {
  searchText: string;
  closePanel: (deleteText?: boolean) => void;
}) {
  const { t } = useTranslation();
  const editor = useSlate();
  const [selectedOptionId, setSelectedOptionId] = useState<string>('');

  const onClick = useCallback(
    (type: MentionType, mention: Mention) => {
      closePanel(false);
      CustomEditor.insertMention(editor, mention);
    },
    [closePanel, editor]
  );
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

  const options = useMemo(() => {
    return [
      {
        key: MentionType.PageRef,
        label: t('document.mention.page.label'),
        options: recentPages.map((page) => {
          return {
            key: page.id,
            label: page.name,
            icon: page.icon,
            onClick: () => {
              onClick(MentionType.PageRef, {
                page: page.id,
              });
            },
          };
        }),
      },
    ].filter((option) => option.options.length > 0);
  }, [onClick, recentPages, t]);

  return {
    options,
    selectedOptionId,
    setSelectedOptionId,
  };
}
