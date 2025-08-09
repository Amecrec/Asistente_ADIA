import { Router } from 'express';
import { pool } from '../config/db.js';
import { requireAuth } from '../middlewares/requireAuth.js';

const router = Router();

// Generar borrador de planeación + secciones (tabs)
router.post('/generar-planeacion', requireAuth, async (req, res, next) => {
  const client = await pool.connect();
  try {
    const {
      usuario_id,                 // opcional, si no llega usamos req.user.id
      tipo,                       // 'secuencial' | 'proyecto'
      grado,
      campo_formativo,
      contenido,                  // temaCentral mapeado a contenido
      sesiones,
      duracion,
      tema,
      pilares = {},               // objeto { clave: valor }
      secciones = {}              // { planeacion, material_apoyo, rubrica, lista_cotejo } => objetos/markdown
    } = req.body;

    const userId = usuario_id || req.user?.id;
    if (!userId) return res.status(400).json({ error: 'usuario_id requerido' });
    if (!tipo || !contenido) return res.status(400).json({ error: 'tipo y contenido son requeridos' });

    await client.query('BEGIN');

    const { rows: planRows } = await client.query(
      `INSERT INTO planeaciones (usuario_id, tipo, grado, campo_formativo, contenido, sesiones, duracion, tema)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING id`,
      [userId, tipo, grado || null, campo_formativo || null, contenido, sesiones || null, duracion || null, tema || null]
    );
    const planeacionId = planRows[0].id;

    // Insertar pilares
    const pKeys = Object.keys(pilares || {});
    for (const clave of pKeys) {
      await client.query(
        `INSERT INTO plan_pilares (planeacion_id, clave, valor)
         VALUES ($1,$2,$3)
         ON CONFLICT (planeacion_id, clave) DO UPDATE SET valor=EXCLUDED.valor`,
        [planeacionId, clave, JSON.stringify(pilares[clave])]
      );
    }

    // Insertar secciones (tabs)
    const sectionMap = secciones || {};
    for (const seccion of ['planeacion', 'material_apoyo', 'rubrica', 'lista_cotejo']) {
      if (sectionMap[seccion]) {
        await client.query(
          `INSERT INTO plan_secciones (planeacion_id, seccion, contenido, es_editado_por_docente)
           VALUES ($1,$2,$3,false)`,
          [planeacionId, seccion, JSON.stringify(sectionMap[seccion])]
        );
      }
    }

    await client.query('COMMIT');
    res.status(201).json({ planeacion_id: planeacionId });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// Obtener contenidos base (para formularios)
router.get('/contenidos', async (req, res, next) => {
  try {
    const { grado, campo_formativo } = req.query;
    const values = [];
    const where = [];
    if (grado) { values.push(grado); where.push(`grado = $${values.length}`); }
    if (campo_formativo) { values.push(campo_formativo); where.push(`campo_formativo = $${values.length}`); }

    const sql = `
      SELECT id, grado, campo_formativo, contenido, bloque, codigo, metadata
      FROM contenidos_base
      ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
      ORDER BY grado, campo_formativo, contenido
      LIMIT 500
    `;
    const { rows } = await pool.query(sql, values);
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

export default router;
