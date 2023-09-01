import { useAppSelector } from '$app/stores/store';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { useRef } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { EyeOpenSvg } from '$app/components/_shared/svg/EyeOpenSvg';

export const BoardFieldsPopup = ({ hidePopup }: { hidePopup: () => void }) => {
  const columns = useAppSelector((state) => state.database.columns);
  const fields = useAppSelector((state) => state.database.fields);
  const ref = useRef<HTMLDivElement>(null);

  useOutsideClick(ref, () => hidePopup());

  return (
    <div ref={ref} className={'absolute left-full top-full z-10 rounded-lg bg-white px-2 py-2 text-xs shadow-md'}>
      {columns.map((column, index) => (
        <div
          className={'flex cursor-pointer items-center justify-between rounded-lg px-2 py-2 hover:bg-fill-list-hover'}
          key={index}
        >
          <div className={'flex items-center gap-2 '}>
            <i className={'flex h-5 w-5 flex-shrink-0 items-center justify-center'}>
              <FieldTypeIcon fieldType={fields[column.fieldId].fieldType}></FieldTypeIcon>
            </i>
            <span className={'flex-shrink-0'}>{fields[column.fieldId].title}</span>
          </div>
          <div className={'ml-12'}>
            <i className={'block h-5 w-5'}>
              <EyeOpenSvg></EyeOpenSvg>
            </i>
          </div>
        </div>
      ))}
    </div>
  );
};
