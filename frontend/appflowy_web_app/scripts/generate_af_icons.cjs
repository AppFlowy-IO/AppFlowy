const fs = require('fs');
const path = require('path');

const getIconsDir = () => path.resolve(__dirname, '../public/af_icons');

const readSvgFile = (filePath) => {
  return fs.readFileSync(filePath, 'utf8');
};

const renameSvgFile = (filePath, newName) => {
  const newPath = path.join(path.dirname(filePath), newName);
  fs.renameSync(filePath, newPath);
};

const processSvgFiles = (dirPath) => {
  const categories = {};

  const traverseDir = (currentPath) => {
    const items = fs.readdirSync(currentPath);

    items.forEach((item) => {
      const itemPath = path.join(currentPath, item);
      const stat = fs.statSync(itemPath);

      if (stat.isDirectory()) {
        traverseDir(itemPath);
      } else if (stat.isFile() && path.extname(item) === '.svg') {
        const category = path.basename(currentPath);
        const [namePart, ...keywordParts] = path.basename(item, '.svg').split('--');
        const name = namePart;
        const keywords = keywordParts.length > 0 ? keywordParts[0].split('-') : [];
        const svgContent = readSvgFile(itemPath);
        renameSvgFile(itemPath, `${name}.svg`);
        if (!categories[category]) {
          categories[category] = [];
        }

        categories[category].push({
          id: `${category}/${name}`,
          name,
          keywords,
          content: svgContent,
        });
      }
    });
  };

  traverseDir(dirPath);
  return categories;
};

const outputJson = (data, outputFilePath) => {
  fs.writeFileSync(outputFilePath, JSON.stringify(data, null, 2));
};

const main = () => {
  const iconsDirPath = getIconsDir();
  const categories = processSvgFiles(iconsDirPath);
  const outputFilePath = path.join(iconsDirPath, 'icons.json');
  outputJson(categories, outputFilePath);
  console.log(`JSON data has been written to ${outputFilePath}`);
};

main();
