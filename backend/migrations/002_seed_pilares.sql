-- Catálogo de 9 pilares (orden recomendado)
INSERT INTO pilares_catalogo (clave, nombre, descripcion, orden) VALUES
  ('rol', 'Rol', 'Rol/autoridad experta desde la cual habla la IA.', 1),
  ('contexto', 'Contexto', 'Antecedentes, marco, restricciones del problema.', 2),
  ('objetivo', 'Objetivo', 'Meta concreta a lograr con el output.', 3),
  ('formato', 'Formato', 'Estructura, secciones, estilo de entrega.', 4),
  ('tono', 'Tono', 'Voz, estilo comunicativo y nivel de formalidad.', 5),
  ('audiencia', 'Audiencia', 'Para quién está escrito el resultado.', 6),
  ('restricciones', 'Restricciones', 'Límites, reglas y no-hacer.', 7),
  ('instrucciones', 'Instrucciones', 'Pasos, criterios de ejecución y proceso.', 8),
  ('criterios_exito', 'Criterios de Éxito', 'Qué valida que el resultado es correcto.', 9)
ON CONFLICT (clave) DO NOTHING;
