import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import { BlockCommonProps } from '@/appflowy_app/interfaces';

export default function PageBlock({ node }: BlockCommonProps<TreeNode>) {
  return <div className='cursor-pointer underline'>{node.data.title}</div>;
}
