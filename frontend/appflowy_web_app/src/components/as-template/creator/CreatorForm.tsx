import { TemplateCreatorFormValues } from '@/application/template.type';
import AccountLinks from '@/components/as-template/creator/AccountLinks';
import CreatorAvatar from '@/components/as-template/creator/CreatorAvatar';
import { FormControl, FormLabel, TextField } from '@mui/material';
import React, { forwardRef } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';

const CreatorForm = forwardRef<HTMLInputElement, {
  defaultValues?: TemplateCreatorFormValues;
  onSubmit: (data: TemplateCreatorFormValues) => void;
}>(({
  defaultValues,
  onSubmit,
}, ref) => {
  const { t } = useTranslation();
  const {
    watch,
    control,
    handleSubmit,
  } = useForm<TemplateCreatorFormValues>({
    defaultValues,
  });
  const name = watch('name');

  return (
    <form
      className={'flex flex-col gap-4 py-5 overflow-hidden'}
      onSubmit={handleSubmit(onSubmit)}
      onClick={e => e.stopPropagation()}
    >
      <Controller
        control={control}
        name="avatar_url"
        rules={{
          required: false,
        }}

        render={({ field }) => (
          <div className={'flex items-center justify-center'}>
            <CreatorAvatar size={80} src={field.value} enableUpload onChange={field.onChange} name={name} />
          </div>
        )}

      />
      <Controller
        name="name"
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.creator.name'),
          }),
        }}

        render={({ field, fieldState }) => (
          <TextField
            fullWidth
            error={!!fieldState.error}
            helperText={fieldState.error?.message}
            required
            {...field}
            label={t('template.creator.name')}
          />
        )}

      />

      <Controller
        control={control}
        name="account_links"
        rules={{
          validate: (value) => {
            if (!value) return;
            const links = value.filter((link) => link.url.length > 0);

            if (links.length === 0) {
              return t('template.requiredField', {
                field: t('template.creator.accountLinks'),
              });
            }

            return true;
          },
        }}

        render={({ field, fieldState }) => (
          <FormControl className={'flex flex-col gap-4'} error={!!fieldState.error}>
            <FormLabel error={!!fieldState.error} required className={'text-text-caption flex items-center text-md'}>{
              t('template.creator.accountLinks')
            }</FormLabel>
            <AccountLinks value={field.value} onChange={field.onChange} />

          </FormControl>
        )}
      />

      <input type="submit" hidden ref={ref} />
    </form>
  );
});

export default CreatorForm;