import CollaborativeEditor from '@/components/editor/CollaborativeEditor';

export const Editor = ({ workspaceId, documentId }: {
  documentId: string;
  workspaceId: string;
}) => {
  return <CollaborativeEditor workspaceId={workspaceId} documentId={documentId} />;
};