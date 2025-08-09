/**
 * Ejecuta todos los .sql en backend/migrations en orden alfabético.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from '../src/config/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function run() {
  const dir = path.join(__dirname, '../migrations');
  const files = fs.readdirSync(dir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  if (files.length === 0) {
    console.log('No hay migraciones .sql en /migrations');
    process.exit(0);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const f of files) {
      const sql = fs.readFileSync(path.join(dir, f), 'utf8');
      console.log(`→ Ejecutando ${f}`);
      await client.query(sql);
    }
    await client.query('COMMIT');
    console.log('✅ Migraciones ejecutadas con éxito');
    process.exit(0);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Error en migraciones:', err);
    process.exit(1);
  } finally {
    client.release();
  }
}

run();
