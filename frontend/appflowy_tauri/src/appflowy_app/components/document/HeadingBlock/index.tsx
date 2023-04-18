import TextBlock from '../TextBlock';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import { TextDelta } from '@/appflowy_app/interfaces/document';

const fontSize: Record<string, string> = {
  1: 'mt-8 text-3xl',
  2: 'mt-6 text-2xl',
  3: 'mt-4 text-xl',
};

export default function HeadingBlock({ node, delta }: { node: Node; delta: TextDelta[] }) {
  return (
    <div className={`${fontSize[node.data.style?.level]} font-semibold	`}>
      {/*<TextBlock node={node} childIds={[]} delta={delta} />*/}
    </div>
  );
}
