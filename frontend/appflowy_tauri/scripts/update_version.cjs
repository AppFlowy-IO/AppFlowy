const fs = require('fs');
const path = require('path');

if (process.argv.length < 3) {
    console.error('Usage: node update-tauri-version.js <version>');
    process.exit(1);
}

const newVersion = process.argv[2];

const tauriConfigPath = path.join(__dirname, '../src-tauri', 'tauri.conf.json');

fs.readFile(tauriConfigPath, 'utf8', (err, data) => {
    if (err) {
        console.error('Error reading tauri.conf.json:', err);
        return;
    }

    const config = JSON.parse(data);

    config.package.version = newVersion;

    fs.writeFile(tauriConfigPath, JSON.stringify(config, null, 2), 'utf8', (err) => {
        if (err) {
            console.error('Error writing tauri.conf.json:', err);
            return;
        }

        console.log(`Tauri version updated to ${newVersion} successfully.`);
    });
});
