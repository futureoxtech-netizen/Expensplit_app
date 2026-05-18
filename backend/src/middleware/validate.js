export const validate = (schema, source = 'body') => (req, _res, next) => {
  const parsed = schema.parse(req[source]);
  req[source] = parsed;
  next();
};
