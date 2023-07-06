const i18nJSON = require('../../appflowy_flutter/assets/translations/en.json');
const fs = require('fs');

function flattenJSON(obj, prefix = '') {
  let result = {};

  for (let key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      const nestedKeys = flattenJSON(obj[key], `${prefix}${key}.`);
      result = { ...result, ...nestedKeys };
    } else {
      result[`${prefix}${key}`] = obj[key];
    }
  }

  return result;
}

const outputJSON = flattenJSON(i18nJSON);
fs.writeFile('./src/appflowy_app/@types/i18n.json', new Uint8Array(Buffer.from(JSON.stringify(outputJSON))), (res) => {
  if (res) {
    console.error(res);
  }
})
