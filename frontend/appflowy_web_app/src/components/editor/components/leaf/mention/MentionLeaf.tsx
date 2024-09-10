import { Mention, MentionType } from '@/application/types';
import MentionDate from '@/components/editor/components/leaf/mention/MentionDate';
import MentionPage from '@/components/editor/components/leaf/mention/MentionPage';
import { useMemo } from 'react';

export function MentionLeaf({ mention }: { mention: Mention }) {
  const { type, date, page_id, reminder_id, reminder_option } = mention;

  const reminder = useMemo(() => {
    return reminder_id ? { id: reminder_id ?? '', option: reminder_option ?? '' } : undefined;
  }, [reminder_id, reminder_option]);

  if (type === MentionType.PageRef && page_id) {
    return <MentionPage pageId={page_id} />;
  }

  if (type === MentionType.Date && date) {
    return <MentionDate date={date} reminder={reminder} />;
  }

  return null;
}

export default MentionLeaf;
