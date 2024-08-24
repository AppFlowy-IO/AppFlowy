import { TemplateSummary } from '@/application/template.type';
import RelatedTemplates from '@/components/as-template/related-template/RelatedTemplates';
import {
  InputLabel,
  TextField,
} from '@mui/material';
import React, { forwardRef, useMemo } from 'react';
import { useForm, Controller } from 'react-hook-form';
import { useTranslation } from 'react-i18next';

export interface AsTemplateFormValue {
  name: string;
  description: string;
  about: string;
  related_view_ids: string[];
}

function AsTemplateForm ({ viewUrl, defaultValues, onSubmit, defaultRelatedTemplates }: {
  viewUrl: string;
  defaultValues: AsTemplateFormValue;
  onSubmit: (data: AsTemplateFormValue) => void;
  defaultRelatedTemplates?: TemplateSummary[];
}, ref: React.ForwardedRef<HTMLInputElement>) {
  const { control, handleSubmit } = useForm<AsTemplateFormValue>({
    defaultValues,
  });

  const { t } = useTranslation();

  const iframeUrl = useMemo(() => {
    const url = new URL(viewUrl);

    url.searchParams.set('theme', 'light');
    url.searchParams.set('template', 'true');
    return url.toString();
  }, [viewUrl]);

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className={'flex p-20 flex-col gap-4 max-w-screen h-fit w-[964px] min-w-0'}
    >

      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.name'),
          }),
        }}

        render={({ field, fieldState }) => (
          <TextField
            error={!!fieldState.error}
            helperText={fieldState.error?.message} required {...field}
            label={t('template.name')}
          />
        )}
        name="name"
      />


      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.description'),
          }),
        }}
        render={({ field, fieldState }) => (
          <TextField
            error={!!fieldState.error}
            helperText={fieldState.error?.message}
            required
            minRows={3}
            multiline {...field} label={t('template.description')}
          />

        )}
        name="description"
      />


      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.about'),
          }),
        }}
        render={({ field, fieldState }) => (
          <TextField
            error={!!fieldState.error}
            helperText={fieldState.error?.message}
            required
            minRows={3}
            multiline
            {...field}
            label={t('template.about')}
          />
        )}
        name="about"
      />

      <div className={'flex gap-2 flex-col w-full'}>
        <InputLabel>{t('template.preview')}</InputLabel>
        <iframe src={iframeUrl} className={'border aspect-video rounded-[16px] w-full bg-white'} />
      </div>

      <Controller
        control={control}
        render={({ field }) => (
          <RelatedTemplates {...field} defaultRelatedTemplates={defaultRelatedTemplates} />
        )}
        name="related_view_ids"
      />
      <input type="submit" hidden ref={ref} />
    </form>
  );
}

export default forwardRef(AsTemplateForm);