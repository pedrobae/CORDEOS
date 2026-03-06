const globals = require("globals");
const js = require("@eslint/js");

module.exports = [
    {
        ignores: ["node_modules/", "dist/"],
    },
    {
        files: ["**/*.js"],
        languageOptions: {
            globals: {
                ...globals.node,
            },
            ecmaVersion: 2020,
            sourceType: "commonjs",
        },
        rules: {
            ...js.configs.recommended.rules,
            "no-restricted-globals": ["error", "name", "length"],
            "prefer-arrow-callback": "error",
            "quotes": ["error", "double", {
                "allowTemplateLiterals": true,
            }],
        },
    },
    {
        files: ["**/*.spec.js"],
        languageOptions: {
            globals: {
                ...globals.mocha,
            },
        },
    },
];
