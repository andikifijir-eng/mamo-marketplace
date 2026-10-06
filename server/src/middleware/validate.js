// Validasi body dengan zod schema; throw ke errorHandler kalau gagal
function validate(schema) {
  return (req, res, next) => {
    req.body = schema.parse(req.body);
    next();
  };
}

module.exports = { validate };
