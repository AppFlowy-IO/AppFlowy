import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { TextField } from '@mui/material';
import { useLoadDatabaseList } from '$app/components/editor/components/blocks/database/DatabaseList.hooks';
import { ViewLayoutPB } from '@/services/backend';
import { ReactComponent as GridSvg } from '$app/assets/grid.svg';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { GridNode } from '$app/application/document/document.types';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { Page } from '$app_reducers/pages/slice';

function DatabaseList({
  node,
  toggleDrawer,
}: {
  node: GridNode;
  toggleDrawer: (open: boolean) => (e: React.MouseEvent | KeyboardEvent | React.FocusEvent) => void;
}) {
  const scrollRef = React.useRef<HTMLDivElement>(null);

  const inputRef = React.useRef<HTMLElement>(null);
  const editor = useSlateStatic();
  const { t } = useTranslation();
  const [searchText, setSearchText] = React.useState<string>('');
  const { list } = useLoadDatabaseList({
    searchText: searchText || '',
    layout: ViewLayoutPB.Grid,
  });

  const renderItem = useCallback(
    (item: Page) => {
      return (
        <div className={'flex items-center text-text-title'}>
          <GridSvg className={'mr-2 h-4 w-4'} />
          <div className={'truncate'}>{item.name.trim() || t('menuAppHeader.defaultNewPageName')}</div>
        </div>
      );
    },
    [t]
  );

  const options: KeyboardNavigationOption[] = useMemo(() => {
    return list.map((item) => {
      return {
        key: item.id,
        content: renderItem(item),
      };
    });
  }, [list, renderItem]);

  const handleSelected = useCallback(
    (id: string) => {
      CustomEditor.setGridBlockViewId(editor, node, id);
    },
    [editor, node]
  );

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.stopPropagation();
        e.preventDefault();
        toggleDrawer(false)(e);
      }
    },
    [toggleDrawer]
  );

  return (
    <div className={'relative flex h-full flex-col gap-1.5 p-2'}>
      <TextField
        variant={'standard'}
        autoFocus={true}
        spellCheck={false}
        onBlur={toggleDrawer(false)}
        inputRef={inputRef}
        className={'sticky top-0 z-10 px-2'}
        value={searchText}
        onChange={(e) => {
          setSearchText((e.currentTarget as HTMLInputElement).value);
        }}
        inputProps={{
          className: 'py-2 text-sm',
        }}
        placeholder={t('document.plugins.database.linkToDatabase')}
      />
      <div ref={scrollRef} className={'flex-1 overflow-y-auto overflow-x-hidden'}>
        <KeyboardNavigation
          disableFocus={true}
          onKeyDown={handleKeyDown}
          focusRef={inputRef}
          scrollRef={scrollRef}
          options={options}
          onConfirm={handleSelected}
        />
      </div>
    </div>
  );
}

export default DatabaseList;
