// Placeholder: por ahora solo revisa que venga algún Bearer token.
// Luego lo cambiaremos a JWT real o a sesión con Passport.
export function requireAuth(req, res, next) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'No autorizado' });
  }
  // TODO: validar token real
  req.user = { id: req.headers['x-user-id'] || null }; // provisional
  next();
}
