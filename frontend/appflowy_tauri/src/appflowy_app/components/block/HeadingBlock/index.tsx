import TextBlock from '../TextBlock';
import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import { BlockCommonProps } from '@/appflowy_app/interfaces';

const fontSize: Record<string, string> = {
  1: 'mt-8 text-3xl',
  2: 'mt-6 text-2xl',
  3: 'mt-4 text-xl',
};

export default function HeadingBlock({ node, version }: BlockCommonProps<TreeNode>) {
  return (
    <div className={`${fontSize[node.data.level]} font-semibold	`}>
      <TextBlock version={version} node={node} needRenderChildren={false} />
    </div>
  );
}
