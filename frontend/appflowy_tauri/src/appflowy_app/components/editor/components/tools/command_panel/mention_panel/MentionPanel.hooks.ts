import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlate } from 'slate-react';
import { EditorProps, Mention, MentionPage, MentionType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';

export function useMentionPanel({
  closePanel,
  searchText,
  getRecentPages,
}: {
  searchText: string;
  closePanel: (deleteText?: boolean) => void;
  getRecentPages: EditorProps['getRecentPages'];
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

  const pagesRef = useRef<MentionPage[]>([]);
  const [recentPages, setPages] = useState<MentionPage[]>([]);

  const loadPages = useCallback(async () => {
    if (!getRecentPages) return;

    const pages = await getRecentPages();

    pagesRef.current = pages;
    setPages(pages);
  }, [getRecentPages]);

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
