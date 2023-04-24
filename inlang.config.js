
// @ts-check

/**
 * @type { import("@inlang/core/config").DefineConfig }
 */
export async function defineConfig(env) {
  const plugin = await env.$import(
    "https://cdn.jsdelivr.net/gh/samuelstroschein/inlang-plugin-json@1.1.1/dist/index.js"
  );

  const { default: standardLintRules } = await env.$import(
    "https://cdn.jsdelivr.net/gh/inlang/standard-lint-rules@1.1.1/dist/index.js"
  );

  const pluginConfig = {
    pathPattern: "./frontend/appflowy_flutter/assets/translations/{language}.json",
  };

  return {
    referenceLanguage: "en",
    languages: await plugin.getLanguages({ ...env, pluginConfig }),
    readResources: (args) => plugin.readResources({ ...args, ...env, pluginConfig }),
    writeResources: (args) => plugin.writeResources({ ...args, ...env, pluginConfig }),
    lint: {
      rules: [standardLintRules()],
    },
  };
}