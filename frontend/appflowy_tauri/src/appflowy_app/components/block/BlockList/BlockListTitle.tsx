import TextBlock from '../TextBlock';
import { TreeNode } from '$app/block_editor/tree_node';

export default function BlockListTitle({ node }: { node: TreeNode }) {
  return (
    <div className='doc-title max-w-screen flex w-[900px] min-w-0 pt-[50px] text-4xl font-bold'>
      <TextBlock
        toolbarProps={{
          showGroups: [],
        }}
        node={node}
        needRenderChildren={false}
      />
    </div>
  );
}
