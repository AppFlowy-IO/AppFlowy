import { IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as TemplateIcon } from '@/assets/template.svg';
import { useNavigate } from 'react-router-dom';
import { ReactComponent as TrashIcon } from '@/assets/trash.svg';
import { QuickNote } from '@/components/app/quick-note';

function SideBarBottom() {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <div
      className={'px-4 sticky bottom-0 bg-bg-base'}
    >
      <div
        className={'flex py-4  border-t border-line-divider gap-1 justify-around items-center'}

      >
        <Tooltip title={t('template.label')}>
          <IconButton
            size={'small'}
            onClick={() => {
              window.open('https://appflowy.io/templates', '_blank');
            }}
          >
            <TemplateIcon/>
          </IconButton>
        </Tooltip>

        <Tooltip title={t('trash.text')}>
          <IconButton
            size={'small'}
            onClick={() => {
              navigate('/app/trash');
            }}
          >
            <TrashIcon/>
          </IconButton>
        </Tooltip>

        <QuickNote/>
      </div>

    </div>
  );
}

export default SideBarBottom;