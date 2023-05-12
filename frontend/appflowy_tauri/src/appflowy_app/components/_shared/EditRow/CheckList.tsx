import { SelectOptionCellDataPB } from '@/services/backend';
import {useRef} from "react";

export const CheckList = ({
  data,
  onEditClick,
}: {
  data: SelectOptionCellDataPB | undefined;
  onEditClick: (left: number, top: number) => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);

  const onClick = () => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    onEditClick(left, top);
  };

  return <div
    ref={ref}
    onClick={() => onClick()}
    className={'flex w-full flex-wrap items-center gap-2 px-4 py-1 text-xs text-black'}
  >Checklist</div>;
};
