import { YjsDatabaseKey } from '@/application/types';
import { FieldType } from '@/application/database-yjs/database.type';
import { useFieldSelector } from '@/application/database-yjs/selector';
import { DateFormat, TimeFormat, getDateFormat, getTimeFormat } from '@/application/database-yjs';
import { renderDate } from '@/utils/time';
import { useCallback, useMemo } from 'react';

export function useCellTypeOption(fieldId: string) {
  const { field } = useFieldSelector(fieldId);
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;

  return useMemo(() => {
    return field?.get(YjsDatabaseKey.type_option)?.get(String(fieldType));
  }, [fieldType, field]);
}

export function useDateTypeCellDispatcher(fieldId: string) {
  const typeOption = useCellTypeOption(fieldId);
  const typeOptionValue = useMemo(() => {
    if (!typeOption) return null;
    return {
      timeFormat: parseInt(typeOption.get(YjsDatabaseKey.time_format)) as TimeFormat,
      dateFormat: parseInt(typeOption.get(YjsDatabaseKey.date_format)) as DateFormat,
    };
  }, [typeOption]);

  const getDateTimeStr = useCallback(
    (timeStamp: string, includeTime?: boolean) => {
      if (!typeOptionValue || !timeStamp) return null;
      const timeFormat = getTimeFormat(typeOptionValue.timeFormat);
      const dateFormat = getDateFormat(typeOptionValue.dateFormat);
      const format = [dateFormat];

      if (includeTime) {
        format.push(timeFormat);
      }

      return renderDate(timeStamp, format.join(' '), true);
    },
    [typeOptionValue]
  );

  return {
    getDateTimeStr,
    typeOptionValue,
  };
}
