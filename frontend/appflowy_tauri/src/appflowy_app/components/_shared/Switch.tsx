export const Switch = ({ value, setValue }: { value: boolean; setValue: (v: boolean) => void }) => {
  return (
    <label className='form-switch' style={{ transform: 'scale(0.5)', marginRight: '-16px' }}>
      <input type='checkbox' checked={value} onChange={() => setValue(!value)} />
      <i></i>
    </label>
  );
};
