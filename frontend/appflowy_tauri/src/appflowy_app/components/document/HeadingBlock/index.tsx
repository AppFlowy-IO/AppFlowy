import TextBlock from '$app/components/document/TextBlock';
import { BlockType, NestedBlock } from '@/appflowy_app/interfaces/document';

const fontSize: Record<string, string> = {
  1: 'mt-5 text-3xl',
  2: 'mt-4 text-2xl',
  3: 'text-xl',
};

export default function HeadingBlock({ node }: { node: NestedBlock<BlockType.HeadingBlock> }) {
  return (
    <div className={`${fontSize[node.data.level]} font-semibold	`}>
      <TextBlock node={node} childIds={[]} />
    </div>
  );
}
