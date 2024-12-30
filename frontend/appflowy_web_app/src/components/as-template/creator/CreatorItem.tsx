import React, { useState } from 'react';
import { TemplateCreator } from '@/application/template.type';
import DeleteCreator from '@/components/as-template/creator/DeleteCreator';
import CreatorAvatar from '@/components/as-template/creator/CreatorAvatar';
import EditCreator from '@/components/as-template/creator/EditCreator';
import { IconButton, Tooltip } from '@mui/material';
import MenuItem from '@mui/material/MenuItem';
import { ReactComponent as CheckIcon } from '@/assets/selected.svg';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { useTranslation } from 'react-i18next';

function CreatorItem ({
  onClick,
  creator,
  selected,
  reloadCreators,
}: {
  onClick: () => void;
  creator: TemplateCreator;
  selected: boolean;
  reloadCreators: () => void;
}) {
  const { t } = useTranslation();
  const [hovered, setHovered] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);

  return (
    <MenuItem
      className={'flex items-center gap-2 justify-between'}
      onClick={onClick}
      onMouseLeave={() => setHovered(false)}
      onMouseEnter={() => setHovered(true)}
    >
      <div
        className={'flex items-center gap-2 border-transparent'}
      >
        <CreatorAvatar size={40} src={creator.avatar_url} name={creator.name} />
        <span className={'text-text-caption'}>{creator.name}</span>
      </div>
      <div style={{
        display: hovered ? 'flex' : 'none',
      }} className={'flex gap-1 items-center'}
      >
        <Tooltip title={t('button.edit')}>
          <IconButton size={'small'} onClick={(e) => {
            e.stopPropagation();
            setEditModalOpen(true);
          }}
          >
            <EditIcon className={'w-4 h-4'} />
          </IconButton>
        </Tooltip>
        <Tooltip title={t('button.delete')}>
          <IconButton size={'small'} onClick={(e) => {
            e.stopPropagation();
            setDeleteModalOpen(true);
          }}
          >
            <DeleteIcon className={'w-4 h-4 text-function-error'} />
          </IconButton>
        </Tooltip>
      </div>
      {selected && !hovered && <CheckIcon className={'w-4 h-4 text-fill-default'} />}
      {
        editModalOpen &&
        <EditCreator
          creator={creator}
          onClose={() => setEditModalOpen(false)}
          openModal={editModalOpen}
          onUpdated={reloadCreators}
        />
      }
      {
        deleteModalOpen &&
        <DeleteCreator
          id={creator.id}
          onClose={() => setDeleteModalOpen(false)}
          open={deleteModalOpen}
          onDeleted={reloadCreators}
        />
      }
    </MenuItem>
  );
}

export default CreatorItem;