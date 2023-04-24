import TextBlock from '../TextBlock';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import { HeadingBlockData } from '@/appflowy_app/interfaces/document';

const fontSize: Record<string, string> = {
  1: 'mt-8 text-3xl',
  2: 'mt-6 text-2xl',
  3: 'mt-4 text-xl',
};

export default function HeadingBlock({
  node,
}: {
  node: Node & {
    data: HeadingBlockData;
  };
}) {
  return (
    <div className={`${fontSize[node.data.level]} font-semibold	`}>
      {/*<TextBlock node={node} childIds={[]} delta={delta} />*/}
    </div>
  );
}
