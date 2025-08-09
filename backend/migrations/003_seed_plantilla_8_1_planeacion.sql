INSERT INTO plantillas (nombre, version, tipo, descripcion, dsl_json, activa)
VALUES (
  'Plantilla Maestra', '8.1', 'planeacion',
  'Plantilla segmentada para generación de planeaciones NEM usando 9 pilares.',
  '{
    "flags": {
      "incluir_instruccion_principal": true,
      "incluir_bloque_criterios_exito": true
    },
    "prioridades": ["rol","contexto","objetivo","formato","tono","audiencia","restricciones","instrucciones","criterios_exito"],
    "bloques": [
      { "clave":"instruccion_principal", "flag":"incluir_instruccion_principal", "requerido": true, "orden": 1 },
      { "clave":"rol", "pilar":"rol", "requerido": true, "orden": 2 },
      { "clave":"contexto", "pilar":"contexto", "requerido": true, "orden": 3 },
      { "clave":"objetivo", "pilar":"objetivo", "requerido": true, "orden": 4 },
      { "clave":"formato", "pilar":"formato", "requerido": true, "orden": 5 },
      { "clave":"tono", "pilar":"tono", "requerido": false, "orden": 6 },
      { "clave":"audiencia", "pilar":"audiencia", "requerido": true, "orden": 7 },
      { "clave":"restricciones", "pilar":"restricciones", "requerido": false, "orden": 8 },
      { "clave":"instrucciones", "pilar":"instrucciones", "requerido": true, "orden": 9 },
      { "clave":"criterios_exito", "pilar":"criterios_exito", "flag":"incluir_bloque_criterios_exito", "requerido": true, "orden": 10 }
    ],
    "mapeos_planeacion": {
      "entrada_formulario": ["grado","campo_formativo","contenido","sesiones","duracion_min","tema_opcional"],
      "salida_editor_tabs": ["planeacion","material_apoyo","rubrica","lista_cotejo"]
    }
  }'::jsonb,
  TRUE
)
ON CONFLICT (nombre, version) DO NOTHING
RETURNING id;
