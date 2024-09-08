import { TemplateCategoryFormValues } from '@/application/template.type';
import BgColorPicker from '@/components/as-template/category/BgColorPicker';
import IconPicker from '@/components/as-template/category/IconPicker';
import { FormControl, FormControlLabel, FormLabel, Radio, RadioGroup, TextField } from '@mui/material';
import React, { forwardRef } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';

const CategoryForm = forwardRef<HTMLInputElement, {
  defaultValues: TemplateCategoryFormValues;
  onSubmit: (data: TemplateCategoryFormValues) => void;
}>(({
  defaultValues,
  onSubmit,
}, ref) => {
  const { t } = useTranslation();
  const {
    control,
    handleSubmit,
  } = useForm<TemplateCategoryFormValues>({
    defaultValues,
  });

  return (
    <form className={'flex flex-col gap-4 py-2'} onSubmit={handleSubmit(onSubmit)}
    >
      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.category.name'),
          }),
        }}

        render={({ field, fieldState }) => (
          <TextField
            error={!!fieldState.error}
            helperText={fieldState.error?.message} required {...field}
            label={t('template.category.name')}
          />
        )}
        name="name"
      />

      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.category.desc'),
          }),
        }}

        render={({ field, fieldState }) => (
          <TextField
            multiline
            minRows={3}
            error={!!fieldState.error}
            helperText={fieldState.error?.message} required {...field}
            label={t('template.category.desc')}
          />
        )}
        name="description"
      />

      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.category.icon'),
          }),
        }}

        render={({ field }) => (
          <IconPicker
            {...field}
          />
        )}
        name="icon"
      />

      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.category.bgColor'),
          }),
        }}

        render={({ field }) => (
          <BgColorPicker
            {...field}
          />
        )}
        name="bg_color"
      />
      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.category.type'),
          }),
        }}
        name="category_type"
        render={({ field }) => (
          <FormControl>
            <FormLabel>{t('template.category.type')}</FormLabel>
            <RadioGroup
              row
              value={field.value}
              onChange={(e) => {
                field.onChange(parseInt(e.target.value, 10));
              }}
            >
              <FormControlLabel value={0} control={<Radio />} label={t('template.category.byUseCase')} />
              <FormControlLabel value={1} control={<Radio />} label={t('template.category.byFeature')} />
            </RadioGroup>
          </FormControl>
        )}

      />
      <Controller
        control={control}
        rules={{
          required: t('template.requiredField', {
            field: t('template.category.priority'),
          }),
        }}

        render={({ field, fieldState }) => (
          <TextField
            type="number"
            error={!!fieldState.error}
            helperText={fieldState.error?.message}
            required
            label={t('template.category.priority')}
            {...field}
            onChange={(e) => {
              field.onChange(parseInt(e.target.value, 10));
            }}
          />
        )}
        name="priority"
      />
      <input type="submit" ref={ref} style={{ display: 'none' }} />
    </form>
  );
});

export default CategoryForm;