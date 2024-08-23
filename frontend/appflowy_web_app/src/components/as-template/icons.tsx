import { TemplateIcon } from '@/application/template.type';
import { ReactComponent as Youtube } from '@/assets/youtube.svg';
import { ReactComponent as Twitter } from '@/assets/twitter.svg';
import { ReactComponent as Instagram } from '@/assets/instagram.svg';
import { ReactComponent as Facebook } from '@/assets/facebook.svg';
import { ReactComponent as Tiktok } from '@/assets/tiktok.svg';
import { ReactComponent as Website } from '@/assets/website.svg';
import { ReactComponent as LinkedInIcon } from '@/assets/linkedin.svg';
import { ReactComponent as LightningIcon } from '@/assets/lightning.svg';
import { ReactComponent as MonitorIcon } from '@/assets/monitor.svg';
import { ReactComponent as Lightbulb } from '@/assets/lightbulb.svg';
import { ReactComponent as GraduationCap } from '@/assets/graduation_cap.svg';
import { ReactComponent as Database } from '@/assets/database.svg';
import { ReactComponent as Columns } from '@/assets/columns.svg';
import { ReactComponent as UsersThree } from '@/assets/users_three.svg';
import { ReactComponent as ChatCircleText } from '@/assets/chat_circle_text.svg';
import { ReactComponent as MegaphoneSimple } from '@/assets/megaphone_simple.svg';
import { ReactComponent as StarIcon } from '@/assets/person.svg';
import { ReactComponent as CurrencyCircleDollar } from '@/assets/currency_circle_dollar.svg';
import { ReactComponent as Sparkle } from '@/assets/sparkle.svg';
import { ReactComponent as Notepad } from '@/assets/notepad.svg';
import { ReactComponent as Book } from '@/assets/book.svg';

const categoryIcons: Record<string, React.ReactElement> = {
  [TemplateIcon.project]: <LightningIcon />,
  [TemplateIcon.engineering]: <MonitorIcon />,
  [TemplateIcon.startups]: <Lightbulb />,
  [TemplateIcon.schools]: <GraduationCap />,
  [TemplateIcon.marketing]: <MegaphoneSimple />,
  [TemplateIcon.management]: <ChatCircleText />,
  [TemplateIcon.humanResources]: <StarIcon />,
  [TemplateIcon.sales]: <CurrencyCircleDollar />,
  [TemplateIcon.teamMeetings]: <UsersThree />,
  [TemplateIcon.ai]: <Sparkle />,
  [TemplateIcon.docs]: <Notepad />,
  [TemplateIcon.wiki]: <Book />,
  [TemplateIcon.database]: <Database />,
  [TemplateIcon.kanban]: <Columns />,
};

export function CategoryIcon ({ icon }: { icon: TemplateIcon }) {
  return categoryIcons[icon] || null;
}

export function accountLinkIcon (type: string) {
  switch (type) {
    case 'youtube':
      return <Youtube className="w-4 h-4" />;
    case 'twitter':
      return <Twitter className="w-4 h-4" />;
    case 'tiktok':
      return <Tiktok className="w-4 h-4" />;
    case 'facebook':
      return <Facebook className="w-4 h-4" />;
    case 'instagram':
      return <Instagram className="w-4 h-4" />;
    case 'linkedin':
      return <LinkedInIcon className="w-4 h-4" />;
    default:
      return <Website className="w-4 h-4" />;
  }
}