# Architecture Diagram

Mermaid diagram illustrating high-level components and their interactions. Replace TBD components with actual names from the codebase when available.

```mermaid
graph TD
  Client[Client / Frontend]
  APIGateway[API Gateway]
  ServiceA[Service A]
  ServiceB[Service B]
  DB[(Database)]
  Cache[(Cache)]
  MQ[(Message Queue)]
  ExternalAPI[(External API)]

  Client --> APIGateway
  APIGateway --> ServiceA
  APIGateway --> ServiceB
  ServiceA --> DB
  ServiceA --> Cache
  ServiceB --> DB
  ServiceB --> MQ
  ServiceA --> ExternalAPI
  MQ --> ServiceA
```

Notes
- This diagram uses generic names. TBD: Replace with actual component names from the repository.
- If your project has multiple apps (frontend, backend services), consider adding separate diagrams per app/service and an integration diagram showing cross-service calls.

