import { UploadTemplatePayload } from '@/application/template.type';
import { notify } from '@/components/_shared/notify';
import { AFScroller } from '@/components/_shared/scroller';
import { useService } from '@/components/app/app.hooks';
import AsTemplateForm, { AsTemplateFormValue } from '@/components/as-template/AsTemplateForm';
import Categories from '@/components/as-template/category/Categories';
import Creator from '@/components/as-template/creator/Creator';
import DeleteTemplate from '@/components/as-template/DeleteTemplate';
import { useLoadTemplate } from '@/components/as-template/hooks';
import { Button, CircularProgress, InputLabel, Paper, Switch } from '@mui/material';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import './template.scss';

function AsTemplate ({
  viewName,
  viewUrl,
  viewId,
}: {
  viewName: string;
  viewUrl: string;
  viewId: string;
}) {
  const [selectedCategoryIds, setSelectedCategoryIds] = useState<string[]>([]);
  const [selectedCreatorId, setSelectedCreatorId] = useState<string | undefined>(undefined);
  const { t } = useTranslation();
  const [isNewTemplate, setIsNewTemplate] = React.useState(false);
  const [isFeatured, setIsFeatured] = React.useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = React.useState(false);
  const service = useService();
  const {
    template,
    loadTemplate,
    loading,
  } = useLoadTemplate(viewId);

  const handleBack = useCallback(() => {
    window.location.href = `${decodeURIComponent(viewUrl)}`;
  }, [viewUrl]);
  const handleSubmit = useCallback(async (data: AsTemplateFormValue) => {
    if (!service || !selectedCreatorId || selectedCategoryIds.length === 0) return;
    const formData: UploadTemplatePayload = {
      ...data,
      view_id: viewId,
      category_ids: selectedCategoryIds,
      creator_id: selectedCreatorId,
      is_new_template: isNewTemplate,
      is_featured: isFeatured,
      view_url: viewUrl,
    };

    try {
      if (template) {
        await service?.updateTemplate(template.view_id, formData);
      } else {
        await service?.createTemplate(formData);
        await loadTemplate();
      }

      notify.info({
        type: 'success',
        title: t('template.uploadSuccess'),
        message: t('template.uploadSuccessDescription'),
        okText: t('template.viewTemplate'),
        onOk: () => {
          const url = import.meta.env.AF_BASE_URL?.includes('test') ? 'https://test.appflowy.io' : 'https://appflowy.io';

          window.open(`${url}/templates/${selectedCategoryIds[0]}/${viewId}`, '_blank');
        },
      });
      handleBack();
    } catch (error) {
      // eslint-disable-next-line
      // @ts-ignore
      notify.error(error.toString());
    }

  }, [service, selectedCreatorId, selectedCategoryIds, viewId, isNewTemplate, isFeatured, viewUrl, template, t, handleBack, loadTemplate]);

  const submitRef = React.useRef<HTMLInputElement>(null);

  useEffect(() => {
    void loadTemplate();
  }, [loadTemplate]);

  useEffect(() => {
    if (!template) return;
    setSelectedCategoryIds(template.categories.map((category) => category.id));
    setSelectedCreatorId(template.creator.id);
    setIsNewTemplate(template.is_new_template);
    setIsFeatured(template.is_featured);
  }, [template]);

  const defaultValue = useMemo(() => {
    if (!template) return {
      name: viewName,
      description: '',
      about: '',
      related_view_ids: [],
    };

    return {
      name: template.name,
      description: template.description,
      about: template.about,
      related_view_ids: template.related_templates?.map((related) => related.view_id) || [],
    };
  }, [template, viewName]);

  return (
    <div className={'flex flex-col gap-4 w-full h-full overflow-hidden'}>
      <div className={'flex items-center justify-between'}>
        <Button
          onClick={handleBack}
          variant={'outlined'}
          color={'inherit'}
          endIcon={<CloseIcon className={'w-4 h-4'} />}
        >
          {t('button.cancel')}
        </Button>
        <div className={'flex items-center gap-2'}>
          {template && <Button
            startIcon={<DeleteIcon />}
            color={'error'}
            onClick={() => {
              setDeleteModalOpen(true);
            }}
            variant={'text'}
          >
            {t('template.deleteTemplate')}
          </Button>}

          <Button onClick={() => {
            submitRef.current?.click();
          }} variant={'contained'} color={'primary'}
          >
            {t('template.asTemplate')}
          </Button>
        </div>

      </div>
      <div className={'flex-1 flex gap-20 overflow-hidden'}>
        <Paper className={'w-full h-full flex-1 flex justify-center overflow-hidden'}>
          <AFScroller className={'w-full h-full flex justify-center'} overflowXHidden>
            {loading ?
              <CircularProgress /> :
              <AsTemplateForm
                defaultValues={defaultValue} viewUrl={viewUrl}
                onSubmit={handleSubmit}
                ref={submitRef}
                defaultRelatedTemplates={template?.related_templates}
              />
            }
          </AFScroller>
        </Paper>
        <div className={'w-[25%] flex flex-col gap-4'}>
          <Categories value={selectedCategoryIds} onChange={setSelectedCategoryIds} />
          <Creator value={selectedCreatorId} onChange={setSelectedCreatorId} />
          <div className={'flex gap-2 items-center'}>
            <InputLabel>{t('template.isNewTemplate')}</InputLabel>
            <Switch

              checked={isNewTemplate}
              onChange={() => setIsNewTemplate(!isNewTemplate)}
            />
          </div>
          <div className={'flex gap-2 items-center'}>
            <InputLabel>{t('template.featured')}</InputLabel>
            <Switch

              checked={isFeatured}
              onChange={() => setIsFeatured(!isFeatured)}
            />
          </div>
        </div>
      </div>
      {deleteModalOpen &&
        <DeleteTemplate
          id={viewId}
          onDeleted={handleBack}
          open={deleteModalOpen}
          onClose={() => setDeleteModalOpen(false)}
        />}
    </div>

  );
}

export default AsTemplate;