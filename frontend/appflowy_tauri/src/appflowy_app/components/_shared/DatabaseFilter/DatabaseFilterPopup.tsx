import { t } from 'i18next';
import AddSvg from '../../_shared/svg/AddSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { FieldTypeIcon } from '../EditRow/FieldTypeIcon';
import { useAppSelector } from '$app/stores/store';
import { IPopupItem, PopupSelect } from '$app/components/_shared/PopupSelect';
import { FieldType, SelectOptionPB } from '@/services/backend';
import { MouseEventHandler, useMemo, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import { SupportedOperatorsByType, TDatabaseOperators } from '$app_reducers/database/slice';

export const DatabaseFilterPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const refContainer = useRef<HTMLDivElement>(null);

  useOutsideClick(refContainer, onOutsideClick);

  // stores
  const columns = useAppSelector((state) => state.database.columns);
  const fields = useAppSelector((state) => state.database.fields);
  const filters = useAppSelector((state) => state.database.filters);

  // values
  const [currentFieldId, setCurrentFieldId] = useState<string | null>(null);
  const [currentOperator, setCurrentOperator] = useState<TDatabaseOperators | null>(null);
  const [currentValue, setCurrentValue] = useState<SelectOptionPB[] | string | boolean | null>(null);

  // ui
  const [showFieldSelect, setShowFieldSelect] = useState(false);
  const refFieldSelect = useRef<HTMLDivElement>(null);
  const [fieldSelectTop, setFieldSelectTop] = useState(0);
  const [fieldSelectLeft, setFieldSelectLeft] = useState(0);

  const [showOperatorSelect, setShowOperatorSelect] = useState(false);
  const refOperatorSelect = useRef<HTMLDivElement>(null);
  const [operatorSelectTop, setOperatorSelectTop] = useState(0);
  const [operatorSelectLeft, setOperatorSelectLeft] = useState(0);

  // not all field types support filtering
  const supportedColumns = useMemo(
    () => columns.filter((column) => SupportedOperatorsByType[fields[column.fieldId].fieldType] !== undefined),
    [columns, fields]
  );

  const onFieldClick: MouseEventHandler = (e) => {
    if (!refFieldSelect.current) return;
    const { left, top, height } = refFieldSelect.current.getBoundingClientRect();

    setFieldSelectTop(top + height + 5);
    setFieldSelectLeft(left);
    setShowFieldSelect(true);
  };

  const onOperatorClick: MouseEventHandler = (e) => {
    if (!refOperatorSelect.current) return;
    const { left, top, height } = refOperatorSelect.current.getBoundingClientRect();

    setOperatorSelectTop(top + height + 5);
    setOperatorSelectLeft(left);
    setShowOperatorSelect(true);
  };

  const onSelectFieldClick = (id: string) => {
    setCurrentFieldId(id);
    setShowFieldSelect(false);
  };

  const onSelectOperatorClick = (operator: TDatabaseOperators) => {
    setCurrentOperator(operator);
    setShowOperatorSelect(false);
  };

  return (
    <>
      <div className={'fixed inset-0 z-10 backdrop-blur-sm'}></div>

      <div className={'fixed inset-0 z-10 flex items-center justify-center overflow-y-auto'}>
        <div className='flex flex-col rounded-lg bg-white shadow-md' ref={refContainer}>
          <div className='px-6 pt-6 text-sm text-shade-3'>{t('grid.settings.filter')}</div>

          <div className='overflow-y-scroll text-sm'>
            {/* null row represents new filter */}
            {filters.concat([null]).map((filter, index: number) => (
              <div className='flex items-center gap-4 px-6 py-6' key={index}>
                <div className={'w-[88px]'}>
                  {index === 0 ? (
                    <span className={'text-sm text-shade-3'}>Where</span>
                  ) : (
                    <div className='rounded-lg border border-gray-300'>and</div>
                  )}
                </div>

                <div
                  ref={refFieldSelect}
                  onClick={onFieldClick}
                  className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                    showFieldSelect ? 'border-main-accent' : 'border-shade-4'
                  }`}
                >
                  {currentFieldId ? (
                    <div className={'flex items-center gap-2'}>
                      <i className={'block h-5 w-5'}>
                        <FieldTypeIcon fieldType={fields[currentFieldId].fieldType}></FieldTypeIcon>
                      </i>
                      <span>{fields[currentFieldId].title}</span>
                    </div>
                  ) : (
                    <span className={'text-shade-4'}>Select a field</span>
                  )}
                  <i
                    className={`h-5 w-5 transition-transform duration-500 ${
                      showFieldSelect ? 'rotate-180' : 'rotate-0'
                    }`}
                  >
                    <DropDownShowSvg></DropDownShowSvg>
                  </i>
                </div>

                <div
                  ref={refOperatorSelect}
                  onClick={onOperatorClick}
                  className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                    showOperatorSelect ? 'border-main-accent' : 'border-shade-4'
                  }`}
                >
                  {currentOperator ? (
                    <span>{currentOperator}</span>
                  ) : (
                    <span className={'text-shade-4'}>Select an option</span>
                  )}
                  <i
                    className={`h-5 w-5 transition-transform duration-500 ${
                      showOperatorSelect ? 'rotate-180' : 'rotate-0'
                    }`}
                  >
                    <DropDownShowSvg></DropDownShowSvg>
                  </i>
                </div>

                <div className='flex w-[180px] items-center justify-between rounded-lg border border-shade-4 px-2 py-1'>
                  <span>Select an option</span>
                  <i className={'h-5 w-5 transition-transform duration-200'}>
                    <DropDownShowSvg></DropDownShowSvg>
                  </i>
                </div>

                <div className=''>
                  <button className={'rounded p-1 hover:bg-main-secondary'}>
                    <i className={'block h-[16px] w-[16px]'}>
                      <Details2Svg />
                    </i>
                  </button>
                </div>
              </div>
            ))}
          </div>

          <hr />

          <button className='flex cursor-pointer items-center gap-2 px-6 py-6 text-sm text-shade-1'>
            <div className='h-5 w-5'>
              <AddSvg />
            </div>
            {t('grid.settings.addFilter')}
          </button>

          {showFieldSelect && (
            <PopupSelect
              items={supportedColumns.map<IPopupItem>((c) => ({
                icon: (
                  <i className={'block h-5 w-5'}>
                    <FieldTypeIcon fieldType={fields[c.fieldId].fieldType}></FieldTypeIcon>
                  </i>
                ),
                title: fields[c.fieldId].title,
                onClick: () => onSelectFieldClick(c.fieldId),
              }))}
              className={'fixed z-10 text-sm'}
              style={{ top: `${fieldSelectTop}px`, left: `${fieldSelectLeft}px`, width: `${180}px` }}
              onOutsideClick={() => setShowFieldSelect(false)}
            ></PopupSelect>
          )}
          {showOperatorSelect && (
            <PopupSelect
              items={SupportedOperatorsByType[
                currentFieldId && fields[currentFieldId] ? fields[currentFieldId].fieldType : FieldType.RichText
              ].map<IPopupItem>((operatorName) => ({
                icon: null,
                title: operatorName,
                onClick: () => onSelectOperatorClick(operatorName),
              }))}
              className={'fixed z-10 text-sm'}
              style={{ top: `${operatorSelectTop}px`, left: `${operatorSelectLeft}px`, width: `${180}px` }}
              onOutsideClick={() => setShowOperatorSelect(false)}
            ></PopupSelect>
          )}
        </div>
      </div>
    </>
  );
};
