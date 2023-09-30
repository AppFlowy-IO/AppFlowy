import React, { useEffect, useState } from 'react';
import { List } from '@mui/material';
import MenuItem from '@mui/material/MenuItem';
import { useLoadRecentPages } from '$app/components/document/Mention/Mention.hooks';
import { useTranslation } from 'react-i18next';
import { Article } from '@mui/icons-material';
import { useBindArrowKey } from '$app/components/document/_shared/useBindArrowKey';

function RecentPages({ searchText, onSelect }: { searchText: string; onSelect: (pageId: string) => void }) {
  const { t } = useTranslation();
  const { recentPages } = useLoadRecentPages(searchText);
  const [selectOption, setSelectOption] = useState<string | null>(null);

  const { run, stop } = useBindArrowKey({
    options: recentPages.map((item) => item.id),
    onChange: (key) => {
      setSelectOption(key);
    },
    selectOption,
    onEnter: () => selectOption && onSelect(selectOption),
  });

  useEffect(() => {
    if (recentPages.length > 0) {
      run();
    } else {
      stop();
    }
  }, [recentPages, run, stop]);

  return (
    <List>
      <div className={'p-2 text-text-caption'}>{t('document.mention.page.label')}</div>
      {recentPages.map((page) => (
        <MenuItem
          style={{
            margin: 0,
            padding: '0.5rem',
          }}
          onMouseEnter={() => {
            setSelectOption(page.id);
          }}
          selected={selectOption === page.id}
          key={page.id}
          onClick={() => {
            onSelect(page.id);
          }}
        >
          <div className={'flex items-center'}>
            <div className={'mr-2'}>{page.icon?.value || <Article />}</div>
            <div>{page.name || t('menuAppHeader.defaultNewPageName')}</div>
          </div>
        </MenuItem>
      ))}
    </List>
  );
}

export default RecentPages;
