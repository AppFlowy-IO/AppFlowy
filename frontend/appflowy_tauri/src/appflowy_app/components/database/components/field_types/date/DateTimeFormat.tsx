import React, { useCallback } from 'react';
import DateFormat from '$app/components/database/components/field_types/date/DateFormat';
import TimeFormat from '$app/components/database/components/field_types/date/TimeFormat';
import { TimeStampTypeOption, UndeterminedDateField, updateTypeOption } from '$app/components/database/application';
import { DateFormatPB, FieldType, TimeFormatPB } from '@/services/backend';
import { useViewId } from '$app/hooks';
import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';
import IncludeTimeSwitch from '$app/components/database/components/field_types/date/IncludeTimeSwitch';

interface Props {
  field: UndeterminedDateField;
}

function DateTimeFormat({ field }: Props) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const showIncludeTime = field.type === FieldType.CreatedTime || field.type === FieldType.LastEditedTime;

  const includeTime = (field.typeOption as TimeStampTypeOption).includeTime;
  const { timeFormat = TimeFormatPB.TwentyFourHour, dateFormat = DateFormatPB.Friendly } = field.typeOption;
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
    <div className={'pl-1 pr-3.5'}>
      <Typography className={'py-1 pl-[18px]'} color={'text.secondary'}>
        {t('grid.field.format')}
      </Typography>
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
        <div className={'py-1 pl-4'}>
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
