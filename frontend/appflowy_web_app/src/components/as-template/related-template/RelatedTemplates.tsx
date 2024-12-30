import { TemplateSummary } from '@/application/template.type';
import AddRelatedTemplates from '@/components/as-template/related-template/AddRelatedTemplates';
import TemplateItem from '@/components/as-template/related-template/TemplateItem';
import { InputLabel, Grid, IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useEffect, useMemo, useRef, forwardRef } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';

function RelatedTemplates ({ value = [], onChange, defaultRelatedTemplates }: {
  value?: string[];
  onChange: (value: string[]) => void;
  defaultRelatedTemplates?: TemplateSummary[];
}, ref: React.ForwardedRef<HTMLDivElement>) {
  const { t } = useTranslation();
  const relatedTemplatesRef = useRef<Map<string, TemplateSummary>>(new Map());

  useEffect(() => {
    defaultRelatedTemplates?.forEach((template) => {
      relatedTemplatesRef.current.set(template.view_id, template);
    });
  }, [defaultRelatedTemplates]);

  const updateTemplate = useCallback((template: TemplateSummary) => {
    relatedTemplatesRef.current.set(template.view_id, template);
  }, []);

  const renderTemplates = useMemo(() => {
    return value.map((id) => {
      const template = relatedTemplatesRef.current.get(id) || defaultRelatedTemplates?.find((t) => t.view_id === id);

      if (!template) return null;
      const currentCategory = template.categories[0];

      return (
        <Grid key={template.view_id} item sm={12} md={6}>
          <div className={'template-item relative'}>
            <TemplateItem template={template} category={currentCategory} />
            <Tooltip title={t('template.removeRelatedTemplate')} placement={'top'}>

              <IconButton
                className={'delete-icon absolute right-2 top-2 bg-bg-body hover:text-function-error'}
                onClick={() => onChange(value.filter((v) => v !== id))}
              >
                <DeleteIcon className={'w-5 h-5'} />
              </IconButton>
            </Tooltip>
          </div>
        </Grid>
      );
    });
  }, [value, t, onChange, defaultRelatedTemplates]);

  return (
    <div ref={ref} className={'flex flex-col gap-4'}>
      <InputLabel>{t('template.relatedTemplates')}</InputLabel>

      <AddRelatedTemplates selectedTemplateIds={value} updateTemplate={updateTemplate} onChange={onChange} />
      <Grid
        container
        className={'templates'}
        rowSpacing={{
          xs: 2,
          sm: 4,
        }}
        columns={{ xs: 4, sm: 8, md: 12 }}
        columnSpacing={{ sm: 2, md: 3 }}
      >
        {renderTemplates}
      </Grid>

    </div>
  );
}

export default forwardRef(RelatedTemplates);