export const validationRegex = {
  link: /(https?\:\/\/[^ ]+)/gi,
  global:
    /(\`.*?\`)|(\@[a-zA-Z0-9_]{4,})|(\:[a-z0-9]+\:)|(https?\:\/\/[^ ]+)/gi,
};
