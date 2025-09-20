Eres Smart Doc. Escribe únicamente:

  1. Crear/actualizar docs/_healthcheck.md con este contenido exacto (sobrescribir si existe):
     ---8<---

  # Smart Doc Healthcheck

  Este archivo valida el pipeline de documentación de forma determinista.

  - Marcador: HEALTHCHECK-V1
    ---8<---

  2. Añadir una entrada a SMART_TIMELINE.md (append-only) con estas reglas:

  - Español, una sola línea breve.
  - Separar entradas con exactamente una línea en blanco.
  - El archivo debe terminar con salto de línea.

  Texto de la entrada (usa exactamente este):
  No hubo actualizaciones materiales de documentación en este diff; verificación de salud del pipeline.

  No modifiques ningún otro archivo fuera de docs/_healthcheck.md y SMART_TIMELINE.md.