// module.exports = {extends: ['@commitlint/config-conventional']}
module.exports = {
    rules: {
        'header-max-length': [2, 'always', 100],

        'type-enum': [2, 'always', ['build', 'chore', 'ci', 'docs', 'feat', 'feature', 'fix', 'refactor', 'style', 'test']],
        'type-empty': [2, 'never'],
        'type-case': [2, 'always', 'lower-case'],

        'subject-empty': [2, 'never'],
        'subject-case': [
            0,
            'never',
            ['sentence-case', 'start-case', 'pascal-case', 'upper-case'],
        ],

        'body-leading-blank': [2, 'always'],
        'body-max-line-length': [2, 'always', 200],
        'body-case': [0, 'never', []],

        'footer-leading-blank': [1, 'always'],
        'footer-max-line-length': [2, 'always', 100]
    },
};

