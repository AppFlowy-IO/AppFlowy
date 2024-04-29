import { Mention, MentionType } from '@/application/document.type';
import MentionDate from '@/components/editor/components/leaf/mention/MentionDate';
import MentionPage from '@/components/editor/components/leaf/mention/MentionPage';

export function MentionLeaf({ mention }: { mention: Mention }) {
  const { type, date, page_id } = mention;

  if (type === MentionType.PageRef && page_id) {
    return <MentionPage pageId={page_id} />;
  }

  if (type === MentionType.Date && date) {
    return <MentionDate date={date} />;
  }

  return null;
}

export default MentionLeaf;
