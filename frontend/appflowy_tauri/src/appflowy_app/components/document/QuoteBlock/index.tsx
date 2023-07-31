import { BlockType, NestedBlock } from '$app/interfaces/document';
import TextBlock from '$app/components/document/TextBlock';
import NodeChildren from '$app/components/document/Node/NodeChildren';

export default function QuoteBlock({
  node,
  childIds,
}: {
  node: NestedBlock<BlockType.QuoteBlock>;
  childIds?: string[];
}) {
  return (
    <div className={'py-[2px]'}>
      <div className={'border-l-4 border-solid border-fill-default px-3 '}>
        <TextBlock node={node} />
        <NodeChildren childIds={childIds} />
      </div>
    </div>
  );
}
