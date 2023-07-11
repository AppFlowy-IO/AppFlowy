import { t } from 'i18next';
import { PopupWindow } from '../../_shared/PopupWindow';
import AddSvg from '../../_shared/svg/AddSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { FieldTypeIcon } from '../EditRow/FieldTypeIcon';
import { useAppSelector } from '$app/stores/store';
import { IPopupItem, PopupSelect } from '$app/components/_shared/PopupSelect';
import { FieldType } from '@/services/backend';
import { MouseEventHandler, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import { SupportedOperatorsByType, TDatabaseOperators } from '$app_reducers/database/slice';

export const DatabaseFilterPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const columns = useAppSelector((state) => state.database.columns);
  const fields = useAppSelector((state) => state.database.fields);
  const filters = useAppSelector((state) => state.database.filters);

  const [showFieldSelect, setShowFieldSelect] = useState(false);
  const refFieldSelect = useRef<HTMLDivElement>(null);
  const [fieldSelectTop, setFieldSelectTop] = useState(0);
  const [fieldSelectLeft, setFieldSelectLeft] = useState(0);

  const [currentField, setCurrentField] = useState<FieldType | null>(null);
  const [currentOperator, setCurrentOperator] = useState<TDatabaseOperators | null>(null);

  const [showOperatorSelect, setShowOperatorSelect] = useState(false);
  const refOperatorSelect = useRef<HTMLDivElement>(null);
  const [operatorSelectTop, setOperatorSelectTop] = useState(0);
  const [operatorSelectLeft, setOperatorSelectLeft] = useState(0);

  const refContainer = useRef<HTMLDivElement>(null);
  useOutsideClick(refContainer, onOutsideClick);

  const onFieldClick: MouseEventHandler = (e) => {
    if (!refFieldSelect.current) return;
    const { left, width, top, height } = refFieldSelect.current.getBoundingClientRect();
    setFieldSelectTop(top + height + 5);
    setFieldSelectLeft(left);
    setShowFieldSelect(true);
  };

  const onOperatorClick: MouseEventHandler = (e) => {
    if (!refOperatorSelect.current) return;
    const { left, width, top, height } = refOperatorSelect.current.getBoundingClientRect();
    setOperatorSelectTop(top + height + 5);
    setOperatorSelectLeft(left);
    setShowOperatorSelect(true);
  };

  return (
    <>
      <div className={'fixed inset-0 z-10 flex items-center justify-center overflow-y-auto'}>
        <div className='flex flex-col rounded-lg bg-white shadow-md' ref={refContainer}>
          <div className='px-6 pt-6 text-sm text-shade-3'>{t('grid.settings.filter')}</div>

          <div className='overflow-y-scroll text-sm'>
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
                  className={`relative flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
                    showFieldSelect ? 'border-main-accent' : 'border-shade-4'
                  }`}
                >
                  <div className={'flex items-center gap-2'}>
                    <i className={'block h-5 w-5'}>
                      <FieldTypeIcon fieldType={FieldType.RichText}></FieldTypeIcon>
                    </i>
                    <span>Name</span>
                  </div>

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
                  className='flex w-[180px] items-center justify-between rounded-lg border border-shade-4 px-2 py-1'
                >
                  <span>Contains</span>
                  <i className={'h-5 w-5 transition-transform duration-200'}>
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
        </div>
      </div>
      {showFieldSelect && (
        <PopupSelect
          items={columns.map<IPopupItem>((c) => ({
            icon: (
              <i className={'block h-5 w-5'}>
                <FieldTypeIcon fieldType={fields[c.fieldId].fieldType}></FieldTypeIcon>
              </i>
            ),
            title: fields[c.fieldId].title,
            onClick: () => {
              console.log('click');
            },
          }))}
          className={'fixed z-10 text-sm'}
          style={{ top: `${fieldSelectTop}px`, left: `${fieldSelectLeft}px`, width: `${180}px` }}
          onOutsideClick={() => setShowFieldSelect(false)}
        ></PopupSelect>
      )}
      {showOperatorSelect && (
        <PopupSelect
          items={SupportedOperatorsByType[currentField ?? FieldType.RichText].map<IPopupItem>((operatorName) => ({
            icon: null,
            title: operatorName,
            onClick: () => {
              console.log('operator');
            },
          }))}
          className={'fixed z-10 text-sm'}
          style={{ top: `${operatorSelectTop}px`, left: `${operatorSelectLeft}px`, width: `${180}px` }}
          onOutsideClick={() => setShowOperatorSelect(false)}
        ></PopupSelect>
      )}
    </>
  );
};
