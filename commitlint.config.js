// module.exports = {extends: ['@commitlint/config-conventional']}
module.exports = {
    rules: {
        'header-max-length': [2, 'always', 100],

        'type-enum': [2, 'always', ['chore', 'ci', 'docs', 'feat', 'fix', 'refactor', 'style', 'test']],
        'type-empty': [2, 'never'],
        'type-case': [2, 'always', 'lower-case'],

        'subject-case': [
            2,
            'never',
            ['sentence-case', 'start-case', 'pascal-case', 'upper-case'],
        ],
        'subject-empty': [2, 'never'],

        'body-leading-blank': [1, 'always'],
        'body-max-line-length': [2, 'always', 100],
        'body-case': [2, 'never', []],

        'footer-leading-blank': [1, 'always'],
        'footer-max-line-length': [2, 'always', 100]
    },
};
