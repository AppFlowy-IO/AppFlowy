import { Link } from 'react-router-dom';

export const Welcome = () => {
  return (
    <div className={'p-4'}>
      <div className={'mb-8 text-2xl'}>Welcome</div>
      <div className={'mb-4'}>
        <Link to={'/page/colors'}>Color Palette</Link>
      </div>
      <div className={'mb-4'}>
        <Link to={'/page/api-test'}>Testing API</Link>
      </div>
    </div>
  );
};
