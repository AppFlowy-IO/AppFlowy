import TestFonts from './components/TestFonts/TestFonts';

const App = () => {
  return (
    <div className='bg-white text-black h-screen w-screen flex'>
      <div className={'w-[200px]'}>Navigation</div>
      <div className={'flex-1'}>
        <TestFonts />
      </div>
    </div>
  );
};

export default App;
