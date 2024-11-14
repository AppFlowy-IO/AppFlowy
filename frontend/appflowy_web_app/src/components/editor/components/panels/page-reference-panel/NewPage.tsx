import { MentionType, ViewLayout } from '@/application/types';
import { useEditorContext } from '@/components/editor/EditorContext';
import { Button, Divider } from '@mui/material';
import React, { useCallback } from 'react';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { ReactComponent as ArrowIcon } from '@/assets/north_east.svg';

import { useTranslation } from 'react-i18next';

function NewPage ({
  onDone,
  name,
}: {
  onDone: (id: string, type: MentionType) => void;
  name: string;
}) {
  const {
    addPage,
    viewId,
  } = useEditorContext();
  const { t } = useTranslation();
  const handleAddSubPage = useCallback(async () => {
    if (!addPage || !viewId) return;
    try {
      const newViewId = await addPage(viewId, ViewLayout.Document, name);

      onDone(newViewId, MentionType.childPage);
    } catch (e) {
      console.error(e);
    }
  }, [addPage, name, onDone, viewId]);

  const handleAddPageReference = useCallback(async () => {
    if (!addPage || !viewId) return;
    try {
      const newViewId = await addPage(viewId, ViewLayout.Document, name);

      onDone(newViewId, MentionType.PageRef);
    } catch (e) {
      console.error(e);
    }
  }, [addPage, name, onDone, viewId]);

  return (
    <div
      className={'flex w-full flex-col gap-2'}
    >
      <Divider />
      <Button
        color={'inherit'}
        startIcon={<AddIcon />}
        size={'small'}
        data-option-key={'sub-page'}
        className={`justify-start scroll-m-2 min-h-[32px] hover:bg-fill-list-hover`}
        onClick={handleAddSubPage}
      >
        <span>{t('button.create')}</span>
        <span className={'mx-1'}>{name ? `"${name}"` : 'new'}</span>
        <span>{t('document.slashMenu.subPage.keyword1')}</span>
      </Button>

      <Button
        color={'inherit'}
        startIcon={<ArrowIcon className={''} />}
        size={'small'}
        data-option-key={'page-reference'}
        className={`justify-start scroll-m-2 min-h-[32px] hover:bg-fill-list-hover`}
        onClick={handleAddPageReference}
      >
        <span>{t('button.create')}</span>
        <span className={'mx-1'}>{name ? `"${name}"` : 'new'}</span>
        <span>page in...</span>
      </Button>
    </div>
  );
}

export default NewPage;