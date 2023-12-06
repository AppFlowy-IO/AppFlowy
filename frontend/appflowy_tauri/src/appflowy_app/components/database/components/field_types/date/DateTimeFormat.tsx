import React, { useCallback } from 'react';
import DateFormat from '$app/components/database/components/field_types/date/DateFormat';
import TimeFormat from '$app/components/database/components/field_types/date/TimeFormat';
import { TimeStampTypeOption, UndeterminedDateField, updateTypeOption } from '$app/components/database/application';
import { DateFormatPB, FieldType, TimeFormatPB } from '@/services/backend';
import { useViewId } from '$app/hooks';
import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';
import IncludeTimeSwitch from '$app/components/database/components/field_types/date/IncludeTimeSwitch';
import { useTypeOption } from '$app/components/database';

interface Props {
  field: UndeterminedDateField;
  showLabel?: boolean;
}

function DateTimeFormat({ field, showLabel = true }: Props) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const showIncludeTime = field.type === FieldType.CreatedTime || field.type === FieldType.LastEditedTime;
  const typeOption = useTypeOption<TimeStampTypeOption>(field.id);
  const { timeFormat = TimeFormatPB.TwentyFourHour, dateFormat = DateFormatPB.Friendly, includeTime } = typeOption;
  const handleChange = useCallback(
    async (params: { timeFormat?: TimeFormatPB; dateFormat?: DateFormatPB; includeTime?: boolean }) => {
      try {
        await updateTypeOption(viewId, field.id, field.type, {
          timeFormat: params.timeFormat ?? timeFormat,
          dateFormat: params.dateFormat ?? dateFormat,
          includeTime: params.includeTime ?? includeTime,
          fieldType: field.type,
        });
      } catch (e) {
        // toast.error(e.message);
      }
    },
    [dateFormat, field.id, field.type, includeTime, timeFormat, viewId]
  );

  return (
    <div>
      {showLabel && (
        <Typography className={'py-1 pl-3'} color={'text.secondary'}>
          {t('grid.field.format')}
        </Typography>
      )}

      <DateFormat
        value={dateFormat}
        onChange={(val) => {
          void handleChange({ dateFormat: val });
        }}
      />
      <TimeFormat
        value={timeFormat}
        onChange={(val) => {
          void handleChange({ timeFormat: val });
        }}
      />

      {showIncludeTime && (
        <div className={'px-3 py-1'}>
          <IncludeTimeSwitch
            size={'small'}
            checked={includeTime}
            onIncludeTimeChange={(checked) => {
              void handleChange({ includeTime: checked });
            }}
          />
        </div>
      )}
    </div>
  );
}

export default DateTimeFormat;
