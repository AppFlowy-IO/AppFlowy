const languages = [
    'ar-SA',
    'ca-ES',
    'de-DE',
    'en',
    'es-VE',
    'eu-ES',
    'fr-FR',
    'hu-HU',
    'id-ID',
    'it-IT',
    'ja-JP',
    'ko-KR',
    'pl-PL',
    'pt-BR',
    'pt-PT',
    'ru-RU',
    'sv-SE',
    'th-TH',
    'tr-TR',
    'zh-CN',
    'zh-TW',
];

const fs = require('fs');
languages.forEach(language => {
    const json = require(`../../../resources/translations/${language}.json`);
    const outputJSON = flattenJSON(json);
    const output = JSON.stringify(outputJSON);
    const isExistDir = fs.existsSync('./src/appflowy_app/i18n/translations');
    if (!isExistDir) {
        fs.mkdirSync('./src/appflowy_app/i18n/translations');
    }
    fs.writeFile(`./src/appflowy_app/i18n/translations/${language}.json`, new Uint8Array(Buffer.from(output)), (res) => {
        if (res) {
            console.error(res);
        }
    })
});


function flattenJSON(obj, prefix = '') {
    let result = {};
    const pluralsKey = ["one", "other", "few", "many", "two", "zero"];

    for (let key in obj) {
        if (typeof obj[key] === 'object' && obj[key] !== null) {

            const nestedKeys = flattenJSON(obj[key], `${prefix}${key}.`);
            result = { ...result, ...nestedKeys };
        } else {
            let newKey = `${prefix}${key}`;
            let replaceChar = '{'
            if (pluralsKey.includes(key)) {
                newKey = `${prefix.slice(0, -1)}_${key}`;
            }
            result[newKey] = obj[key].replaceAll('{', '{{').replaceAll('}', '}}');
        }
    }

    return result;
}

