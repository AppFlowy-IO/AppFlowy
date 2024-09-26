import { Template } from '@/application/template.type';
import { useAppView } from '@/components/app/app.hooks';
import LinkPreview from '@/components/app/share/LinkPreview';
import { useLoadPublishInfo } from '@/components/app/share/publish.hooks';
import AsTemplateButton from '@/components/as-template/AsTemplateButton';
import DeleteTemplate from '@/components/as-template/DeleteTemplate';
import { slugify } from '@/components/as-template/utils';
import { useService } from '@/components/main/app.hooks';
import { Button, Skeleton } from '@mui/material';
import React, { useCallback, useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';

function TemplatePanel () {
  const view = useAppView();
  const service = useService();
  const [loading, setLoading] = React.useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = React.useState(false);
  const [template, setTemplateInfo] = React.useState<Template>();
  const loadTemplateInfo = useCallback(async () => {
    if (!service || !view?.view_id) return;
    setLoading(true);
    try {
      const res = await service.getTemplateById(view?.view_id);

      setTemplateInfo(res);
      // eslint-disable-next-line
    } catch (e: any) {
      // do nothing
    } finally {
      setLoading(false);
    }
  }, [service, view?.view_id]);
  const { t } = useTranslation();
  const {
    url: publishUrl,
  } = useLoadPublishInfo();

  const url = useMemo(() => {
    const origin = import.meta.env.AF_BASE_URL?.includes('test') ? 'https://test.appflowy.io' : 'https://appflowy.io';

    return template ? `${origin}/templates/${slugify(template.categories[0].name)}/${template.view_id}` : '';
  }, [template]);

  useEffect(() => {
    void loadTemplateInfo();
  }, [loadTemplateInfo]);

  const renderLoading = useCallback(() => {
    return <>
      <Skeleton variant={'rectangular'} height={40} />
      <div className={'flex items-center gap-1.5 justify-end w-full'}>
        <Skeleton variant={'rectangular'} height={32} className={'flex-1 max-w-[50%]'} />

        <Skeleton variant={'rectangular'} height={32} className={'flex-1 max-w-[50%]'} />
      </div>
    </>;
  }, []);
  const handleEditClick = useCallback(() => {

    window.open(`${window.origin}/as-template?viewUrl=${encodeURIComponent(publishUrl)}&viewName=${view?.name || ''}&viewId=${view?.view_id || ''}`, '_blank');
  }, [view, publishUrl]);

  const renderTemplateButtons = useCallback(() => {
    return <>
      <LinkPreview url={url} />
      <div className={'flex items-center gap-1.5 justify-end w-full'}>
        <Button
          color={'error'}
          variant={'contained'}
          startIcon={<DeleteIcon />}
          className={'flex-1'} onClick={() => {
          setDeleteModalOpen(true);
        }}
        >
          {t('button.delete')}
        </Button>
        <Button
          startIcon={<EditIcon />}
          className={'flex-1'} onClick={handleEditClick} variant={'outlined'} color={'inherit'}
        >{t('button.edit')}</Button>
      </div>
    </>;
  }, [handleEditClick, t, url]);

  return (
    <div className={'flex flex-col gap-2'}>
      {loading ? renderLoading() : template ? renderTemplateButtons() : <AsTemplateButton />}
      {deleteModalOpen && view &&
        <DeleteTemplate
          id={view.view_id}
          open={deleteModalOpen}
          onDeleted={() => {
            void loadTemplateInfo();
          }}
          onClose={() => setDeleteModalOpen(false)}
        />}
    </div>
  );
}

export default TemplatePanel;