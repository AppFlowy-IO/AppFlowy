import React, { useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { List, MenuItem, TextField } from '@mui/material';
import { useLoadDatabaseList } from '$app/components/editor/components/blocks/database/DatabaseList.hooks';
import { ViewLayoutPB } from '@/services/backend';
import { ReactComponent as GridSvg } from '$app/assets/grid.svg';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { GridNode } from '$app/application/document/document.types';

function DatabaseList({ node }: { node: GridNode }) {
  const editor = useSlateStatic();
  const { t } = useTranslation();
  const [searchText, setSearchText] = React.useState<string>('');
  const [hovered, setHovered] = React.useState<string | null>(null);
  const { list } = useLoadDatabaseList({
    searchText: searchText || '',
    layout: ViewLayoutPB.Grid,
  });

  const handleSelected = useCallback(
    (id: string) => {
      CustomEditor.setGridBlockViewId(editor, node, id);
    },
    [editor, node]
  );

  useEffect(() => {
    if (list.length > 0) {
      setHovered(list[0].id);
    }
  }, [list]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      const index = list.findIndex((item) => item.id === hovered);
      const prevIndex = index - 1;
      const nextIndex = index + 1;

      switch (e.key) {
        case 'ArrowDown':
          e.stopPropagation();
          e.preventDefault();
          if (nextIndex < list.length) {
            setHovered(list[nextIndex].id);
          }

          break;
        case 'ArrowUp':
          e.stopPropagation();
          e.preventDefault();
          if (prevIndex >= 0) {
            setHovered(list[prevIndex].id);
          }

          break;
        case 'Enter':
          e.stopPropagation();
          if (hovered) {
            handleSelected(hovered);
          }

          break;
      }
    },
    [handleSelected, hovered, list]
  );

  return (
    <div className={'relative overflow-y-auto overflow-x-hidden p-2'}>
      <TextField
        onKeyDown={handleKeyDown}
        variant={'standard'}
        autoFocus={true}
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
      <List>
        {list.map((item) => {
          return (
            <MenuItem
              onMouseEnter={() => {
                setHovered(item.id);
              }}
              selected={hovered === item.id}
              key={item.id}
              className={'flex items-center justify-between'}
              onClick={() => {
                handleSelected(item.id);
              }}
            >
              <div className={'flex items-center text-text-title'}>
                <GridSvg className={'mr-2 h-4 w-4'} />
                <div className={'truncate'}>{item.name || t('document.title.placeholder')}</div>
              </div>
            </MenuItem>
          );
        })}
      </List>
    </div>
  );
}

export default DatabaseList;
