export const BoardTextCell = ({ value }: { value: string | undefined }) => {
  return <div>{value || ''}</div>;
};
