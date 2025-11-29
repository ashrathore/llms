# n8n + Ollama + PostgreSQL Demo Stack

A Docker Compose environment for building AI-powered workflows with n8n, local LLMs via Ollama, and PostgreSQL for data storage.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│     n8n     │────▶│   Ollama    │     │  PostgreSQL │
│  :5678      │     │  :11434     │     │    :5432    │
│  Workflows  │     │ llama3.2:3b │     │   logsdb    │
└─────────────┘     └─────────────┘     └─────────────┘
       │                                       │
       └───────────────────────────────────────┘
                    n8n-network
```

## Services

| Service    | Port  | Description                              |
|------------|-------|------------------------------------------|
| n8n        | 5678  | Workflow automation platform             |
| Ollama     | 11434 | Local LLM server with `llama3.2:3b`      |
| PostgreSQL | 5432  | Database with sample API logs            |

## Quick Start

```bash
# Start all services
docker compose -f n8nDemo-compose.yml up -d

# View logs
docker compose -f n8nDemo-compose.yml logs -f

# Stop all services
docker compose -f n8nDemo-compose.yml down

# Stop and remove volumes (clean slate)
docker compose -f n8nDemo-compose.yml down -v
```

## Access Points

- **n8n UI**: http://localhost:5678
- **Ollama API**: http://localhost:11434
- **PostgreSQL**: `localhost:5432`

## PostgreSQL Connection

| Parameter | Value       |
|-----------|-------------|
| Host      | `postgres`  |
| Port      | `5432`      |
| Database  | `logsdb`    |
| Username  | `admin`     |
| Password  | `admin123`  |

> When connecting from n8n, use `postgres` as the host (Docker network name).  
> When connecting externally, use `localhost`.

## Sample Data

The database is pre-loaded with an `api_logs` table in the `logs` schema containing sample API call records:

| Status  | Count | Description                     |
|---------|-------|---------------------------------|
| SUCCESS | 5     | Successful API calls            |
| ERROR   | 5     | Failed requests (4xx/5xx)       |
| WARNING | 2     | Rate limits, cache misses, etc. |

### Table Schema

```sql
logs.api_logs (
    correlation_id UUID PRIMARY KEY,
    timestamp TIMESTAMPTZ,
    service_name VARCHAR(100),
    endpoint VARCHAR(255),
    method VARCHAR(10),
    status_code INTEGER,
    status VARCHAR(20),  -- SUCCESS, ERROR, WARNING
    request_payload JSONB,
    response_payload JSONB,
    error_message TEXT,
    duration_ms INTEGER,
    user_id VARCHAR(100),
    ip_address INET,
    created_at TIMESTAMPTZ
)
```

### Example Queries

```sql
-- Get all error logs
SELECT * FROM logs.api_logs WHERE status = 'ERROR';

-- Find slow requests (>1s)
SELECT service_name, endpoint, duration_ms 
FROM logs.api_logs 
WHERE duration_ms > 1000;

-- Count by service
SELECT service_name, COUNT(*) 
FROM logs.api_logs 
GROUP BY service_name;
```

## Workflow Ideas

1. **Log Analysis Pipeline**  
   Query error logs → Summarize with Ollama → Send alerts

2. **API Health Dashboard**  
   Periodic log aggregation → LLM-generated reports

3. **Anomaly Detection**  
   Monitor slow requests → AI-powered root cause analysis

## Notes

- Ollama automatically pulls the `llama3.2:3b` model on first start (may take a few minutes)
- All data is persisted in Docker volumes (`n8n_data`, `ollama_data`, `postgres_data`)
- Services auto-restart unless manually stopped

