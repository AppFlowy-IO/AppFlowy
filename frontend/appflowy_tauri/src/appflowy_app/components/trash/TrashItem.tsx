import React from 'react';
import dayjs from 'dayjs';
import { IconButton, ListItem } from '@mui/material';
import { DeleteOutline, RestoreOutlined } from '@mui/icons-material';
import Tooltip from '@mui/material/Tooltip';
import { useTranslation } from 'react-i18next';
import { Trash } from '$app_reducers/trash/slice';

function TrashItem({
  item,
  hoverId,
  setHoverId,
  onDelete,
  onPutback,
}: {
  setHoverId: (id: string) => void;
  item: Trash;
  hoverId: string;
  onPutback: (id: string) => void;
  onDelete: (id: string) => void;
}) {
  const { t } = useTranslation();

  return (
    <ListItem
      onMouseEnter={() => {
        setHoverId(item.id);
      }}
      onMouseLeave={() => {
        setHoverId('');
      }}
      key={item.id}
      style={{
        paddingInline: 0,
      }}
    >
      <div className={'flex w-[100%] items-center justify-around gap-2 rounded-lg p-2 text-xs hover:bg-fill-list-hover'}>
        <div className={'w-[40%] whitespace-break-spaces text-left'}>
          {item.name.trim() || t('menuAppHeader.defaultNewPageName')}
        </div>
        <div className={'flex-1'}>{dayjs.unix(item.modifiedTime).format('MM/DD/YYYY hh:mm A')}</div>
        <div className={'flex-1'}>{dayjs.unix(item.createTime).format('MM/DD/YYYY hh:mm A')}</div>
        <div
          style={{
            visibility: hoverId === item.id ? 'visible' : 'hidden',
          }}
          className={'whitespace-nowrap'}
        >
          <Tooltip placement={'top-start'} title={t('button.putback')}>
            <IconButton size={'small'} onClick={(_) => onPutback(item.id)} className={'mr-2'}>
              <RestoreOutlined />
            </IconButton>
          </Tooltip>
          <Tooltip placement={'top-start'} title={t('button.delete')}>
            <IconButton size={'small'} color={'error'} onClick={(_) => onDelete(item.id)}>
              <DeleteOutline />
            </IconButton>
          </Tooltip>
        </div>
      </div>
    </ListItem>
  );
}

export default TrashItem;
