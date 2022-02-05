// module.exports = {extends: ['@commitlint/config-conventional']}
module.exports = {
    rules: {
        'type-enum': [2, 'always', ['feat', 'refactor', 'style', 'fix', 'ci']],
        'body-leading-blank': [1, 'always'],
        'body-max-line-length': [2, 'always', 100],
        'footer-leading-blank': [1, 'always'],
        'footer-max-line-length': [2, 'always', 100],
        'header-max-length': [2, 'always', 100],
        'subject-case': [
            2,
            'never',
            ['sentence-case', 'start-case', 'pascal-case', 'upper-case'],
        ],
        'subject-empty': [2, 'never'],
        'type-empty': [2, 'never'],
        'type-case': [2, 'always', 'lower-case'],
        'body-case': [2, 'never', []]
    },
};
