import React, { useCallback, useMemo } from 'react';
import { NormalModal } from '@/components/_shared/modal';
import { useTranslation } from 'react-i18next';
import { Divider } from '@mui/material';
import { SubscriptionPlan } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/main/app.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';

function CancelSubscribe({ open, onClose, onCanceled }: {
  open: boolean;
  onClose: () => void;
  onCanceled: () => void;
}) {
  const { t } = useTranslation();
  const [page, setPage] = React.useState<number>(0);
  const [loading, setLoading] = React.useState<boolean>(false);
  const service = useService();
  const currentWorkspaceId = useCurrentWorkspaceId();
  const [answers, setAnswers] = React.useState<{
    questionIndex: number;
    answer: string;
  }[]>([]);

  const questions = useMemo(() => {
    return [{
      title: t('subscribe.cancelPlan.questionOne.question'),
      choices: [
        {
          value: 'A',
          label: t('subscribe.cancelPlan.questionOne.answerOne'),
        },
        {
          value: 'B',
          label: t('subscribe.cancelPlan.questionOne.answerTwo'),
        },
        {
          value: 'C',
          label: t('subscribe.cancelPlan.questionOne.answerThree'),
        },
        {
          value: 'D',
          label: t('subscribe.cancelPlan.questionOne.answerFour'),
        },
        {
          value: 'E',
          label: t('subscribe.cancelPlan.questionOne.answerFive'),
        },
      ],
    }, {
      title: t('subscribe.cancelPlan.questionTwo.question'),
      choices: [
        {
          value: 'A',
          label: t('subscribe.cancelPlan.questionTwo.answerOne'),
        },
        {
          value: 'B',
          label: t('subscribe.cancelPlan.questionTwo.answerTwo'),
        },
        {
          value: 'C',
          label: t('subscribe.cancelPlan.questionTwo.answerThree'),
        },
        {
          value: 'D',
          label: t('subscribe.cancelPlan.questionTwo.answerFour'),
        },
        {
          value: 'E',
          label: t('subscribe.cancelPlan.questionTwo.answerFive'),
        },
      ],
    }, {
      title: t('subscribe.cancelPlan.questionThree.question'),
      choices: [
        {
          value: 'A',
          label: t('subscribe.cancelPlan.questionThree.answerOne'),
        },
        {
          value: 'B',
          label: t('subscribe.cancelPlan.questionThree.answerTwo'),
        },
        {
          value: 'C',
          label: t('subscribe.cancelPlan.questionThree.answerThree'),
        },
        {
          value: 'D',
          label: t('subscribe.cancelPlan.questionThree.answerFour'),
        },
      ],
    }, {
      title: t('subscribe.cancelPlan.questionFour.question'),
      choices: [
        {
          value: 'A',
          label: t('subscribe.cancelPlan.questionFour.answerOne'),
        },
        {
          value: 'B',
          label: t('subscribe.cancelPlan.questionFour.answerTwo'),
        },
        {
          value: 'C',
          label: t('subscribe.cancelPlan.questionFour.answerThree'),
        },
        {
          value: 'D',
          label: t('subscribe.cancelPlan.questionFour.answerFour'),
        },
        {
          value: 'E',
          label: t('subscribe.cancelPlan.questionFour.answerFive'),
        },
      ],
    }];
  }, [t]);

  const question = questions[page];

  const handleCancel = useCallback(async () => {
    if (!service || !currentWorkspaceId) return;
    setLoading(true);
    const plan = SubscriptionPlan.Pro;

    try {
      await service.cancelSubscription(currentWorkspaceId, plan, JSON.stringify(answers.map(item => {
        const question = questions[item.questionIndex];

        return {
          question: question.title,
          answer: question.choices.find(choice => choice.value === item.answer)?.label ?? item.answer,
        };
      })));
      notify.success(t('subscribe.cancelPlan.success'));
      onCanceled();
      onClose();
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    }

    setLoading(false);

  }, [answers, currentWorkspaceId, onClose, onCanceled, questions, service, t]);

  const handlePrevious = () => {
    if (page === 0) {
      onClose();
      return;
    }

    setPage(prev => prev - 1);
  };

  const handleNext = useCallback((currentPage: number) => {
    if (currentPage === 3) {
      void handleCancel();
      return;
    }

    setPage(currentPage + 1);

  }, [handleCancel]);

  return (
    <NormalModal
      title={<div className={'text-left font-bold flex gap-2 items-center'}>{t('subscribe.cancelPlan.title')}</div>}
      open={open}
      onClose={() => onClose()}
      onCancel={handlePrevious}
      cancelText={
        page === 0 ? t('button.cancel') : t('button.previous')
      }
      okLoading={loading}
      okButtonProps={{
        disabled: loading,
      }}
      okText={
        page === 3 ? t('button.done') : t('button.next')
      }
      onOk={() => handleNext(page)}
    >
      <div className={'text-text-caption'}>{t('subscribe.cancelPlan.description')}</div>
      <Divider className={'my-4'}/>
      {question && <div className={'flex gap-4 flex-col'}>
        <div className={'text-lg font-medium'}>{question.title}</div>
        <div className={'flex flex-col gap-2'}>
          {question.choices.map((choice) => {
            const selected = answers[page]?.answer === choice.value;

            return <div onClick={() => {
              setAnswers(prev => {
                const newAnswers = [...prev];

                newAnswers[page] = {
                  questionIndex: page,
                  answer: choice.value,
                };

                return newAnswers;
              });
            }} key={choice.value}
                        className={'flex border border-fill-list-hover p-1 hover:bg-fill-list-hover cursor-pointer rounded-[8px] font-medium items-center gap-2'}>
              <span style={{
                backgroundColor: selected ? 'var(--content-blue-300)' : undefined,
                color: selected ? 'var(--content-on-fill)' : undefined,
              }} className={'flex items-center justify-center rounded bg-fill-list-hover text-sm w-6 h-6'}>
                {choice.value}
              </span>
              <span>{choice.label}</span>
            </div>;
          })}
        </div>
      </div>
      }

    </NormalModal>
  );
}

export default CancelSubscribe;