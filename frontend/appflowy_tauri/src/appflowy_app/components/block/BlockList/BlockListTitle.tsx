import TextBlock from '../TextBlock';
import { TreeNode } from '$app/block_editor/view/tree_node';

export default function BlockListTitle({ node }: { node: TreeNode | null }) {
  if (!node) return null;
  return (
    <div data-block-id={node.id} className='doc-title flex pt-[50px] text-4xl font-bold'>
      <TextBlock
        version={0}
        toolbarProps={{
          showGroups: [],
        }}
        node={node}
        needRenderChildren={false}
      />
    </div>
  );
}
