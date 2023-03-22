import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import { BlockCommonProps } from '@/appflowy_app/interfaces';

export default function CodeBlock({ node }: BlockCommonProps<TreeNode>) {
  return <div>{node.data.text}</div>;
}
