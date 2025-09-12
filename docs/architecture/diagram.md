```mermaid
flowchart TD
  EP[entrypoint.sh]
  API[API/Servicio Principal]
  MOD[Modulos/Microservicios]
  DB[(Base de Datos)]
  MQ[(Cola de Mensajes)]
  EP --> API
  API --> DB
  API --> MOD
  MOD --> DB
  API --> MQ
```
Notas
- Este diagrama es un esqueleto inicial. Ajustar para reflejar componentes reales tras analizar el diff.
- Agregar nodos/relaciones adicionales según los módulos detectados en el repositorio.

