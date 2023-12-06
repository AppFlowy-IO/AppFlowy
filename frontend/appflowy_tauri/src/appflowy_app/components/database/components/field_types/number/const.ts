import { NumberFormatPB } from '@/services/backend';

export const formats = Object.entries(NumberFormatPB)
  .filter(([, value]) => typeof value !== 'string')
  .map(([key, value]) => {
    return {
      key,
      value,
    };
  });

export const formatText = (format: NumberFormatPB) => {
  return formats.find((item) => item.value === format)?.key;
};
