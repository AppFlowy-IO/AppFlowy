import { useState } from 'react';

const TestFonts = () => {
  const [sampleText, setSampleText] = useState('Sample Text');

  const onInputChange = (e: any) => {
    setSampleText(e.target.value);
  };

  return (
    <div className={'flex h-full w-full flex-col items-center justify-center'}>
      <div className={'py-2'}>
        <input className={'rounded border border-gray-500 px-2 py-1'} value={sampleText} onChange={onInputChange} />
      </div>
      <div className={'flex flex-1 flex-col items-center justify-center overflow-auto text-2xl'}>
        <div className={'mb-4 font-thin'}>{sampleText} 100 Thin</div>
        <div className={'mb-4 font-extralight'}>{sampleText} 200 Extra Light</div>
        <div className={'mb-4 font-light'}>{sampleText} 300 Light</div>
        <div className={'mb-4 font-normal'}>{sampleText} 400 Regular</div>
        <div className={'mb-4 font-medium'}>{sampleText} 500 Medium</div>
        <div className={'mb-4 font-semibold'}>{sampleText} 600 Semi Bold</div>
        <div className={'mb-4 font-bold'}>{sampleText} 700 Bold</div>
        <div className={'mb-4 font-extrabold'}>{sampleText} 800 Extra Bold</div>
        <div className={'mb-4 font-black'}>{sampleText} 900 Black</div>
      </div>
    </div>
  );
};

export default TestFonts;
