# Token Service

Microsserviço HTTP para validação de tokens JWT conforme regras de negócio específicas.

O objetivo desse projeto é contemplar os requisitos descritos em [BACKEND-CHALLENGE.md](BACKEND-CHALLENGE.md).

## Ambiente local

### Pré-requisitos

- **Elixir** 1.18+ e **Erlang/OTP** 27+
- Para instalar, siga a [documentação oficial](https://elixir-lang.org/install.html)

### Rodando a aplicação

```bash
# Instalar dependências
mix deps.get

# Compilar o projeto
mix compile

# Iniciar o servidor (desenvolvimento)
mix start

# Ou iniciar com logs estruturados em JSON (produção)
MIX_ENV=prod mix start
```

A aplicação estará disponível em [`http://localhost:4000`](http://localhost:4000).

**Endpoints disponíveis:**

- `GET /health` - Health check
- `POST /validate` - Valida um token JWT
- `GET /metrics` - Métricas Prometheus para observabilidade
- `GET /api/openapi` - Especificação OpenAPI 3.0 em JSON
- `GET /api/swagger` - Interface Swagger UI para explorar a API

**Exemplo de requisição:**

```bash
curl -X POST http://localhost:4000/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"}'
```

**Resposta:**

```json
{"valid": true}
```

### Swagger UI

Acesse [`http://localhost:4000/api/swagger`](http://localhost:4000/api/swagger) para:
- Visualizar a especificação OpenAPI completa
- Testar a API diretamente pelo navegador com 3 exemplos prontos:
  - **Valid Token**: Token válido que atende todas as regras de negócio
  - **Invalid Claims**: JWT válido mas com Name contendo números
  - **Malformed JWT**: JWT com estrutura inválida
- Explorar os schemas de validação

### Rodando as suítes de testes

O projeto possui 70+ testes, incluindo testes de unidade e de integração.

#### Executar todos os testes

```bash
mix test
```

#### Executar apenas testes de unidade

```bash
mix test --exclude integration
```

#### Executar apenas testes de integração

```bash
mix test --only integration
```

#### Executar testes de um arquivo específico

```bash
mix test test/token_service/claims_test.exs
```

#### Executar com trace para ver detalhes

```bash
mix test --trace
```

#### Verificação de qualidade

```bash
# Executa compilação com warnings como erros, formata código e roda todos os testes
mix precommit
```

## Observabilidade

### Logs Estruturados

- Produção: Logs em formato JSON com metadados estruturados
- Desenvolvimento: Logs formatados para legibilidade humana
- Teste: Logs capturáveis para testes, saída console mínima

### Saídas de log

#### Validação de token

![Logs de validação de token](docs/token-validation-logs.png)

### Métricas Prometheus

O endpoint `/metrics` expõe métricas em formato Prometheus.

![Exemplo de métricas](docs/metrics-example.png)

**Métricas HTTP:**
- `http_request_count` - Total de requisições HTTP (tags: method, path)

**Métricas customizadas:**
- `token_service_validation_count` - Total de validações por resultado (tags: result=success|failed)
- `token_service_validation_failure_reasons` - Falhas por motivo (tags: reason=invalid_jwt|invalid_claims)

**Métricas de VM:**
- `vm_memory_total_bytes` - Memória total usada pela VM
- `vm_total_run_queue_lengths_total` - Tamanho das filas de execução
- `vm_system_counts_process_count` - Número de processos Erlang

## Visão geral da codebase

| Módulo | Descrição |
|--------|-----------|
| `lib/token_service/application.ex` | Callback de OTP Application. Inicia a árvore de supervisão com Telemetry e servidor HTTP |
| `lib/token_service/router.ex` | Router HTTP usando Plug. Define os endpoints: `/health`, `/validate`, `/metrics` e tratamento de rotas 404 |
| `lib/token_service/jwt_decoder.ex` | Decodifica tokens JWT e extrai claims sem verificação de assinatura |
| `lib/token_service/claims.ex` | Schema Ecto embedded para validação de claims JWT. Implementa todas as regras de negócio (Name, Role, Seed, contagem de claims) |
| `lib/token_service/token_validator.ex` | Orquestra o fluxo de validação: decodifica JWT, valida claims e emite eventos de telemetria |
| `lib/token_service/telemetry.ex` | Configuração de Telemetry e definições de métricas Prometheus (HTTP, validação customizada, VM) |
| `lib/token_service/openapi/` | Módulos relacionados à especificação OpenAPI 3.0 |
| `lib/token_service/openapi/api_spec.ex` | Especificação OpenAPI 3.0 do serviço, define schemas e operações da API |
| `lib/token_service/openapi/schemas/validate_request.ex` | Schema OpenAPI para requisição de validação de token |
| `lib/token_service/openapi/schemas/validate_response.ex` | Schema OpenAPI para resposta de validação de token |

### Testes

| Arquivo/Pasta | Descrição |
|---------------|-----------|
| `test/test_helper.exs` | Configuração do ExUnit para execução de testes |
| `test/token_service/` | Testes unitários dos módulos principais: `claims_test.exs`, `jwt_decoder_test.exs`, `token_validator_test.exs` e seus respectivos doctests |
| `test/integration/` | Testes de integração dos endpoints HTTP: `validate_endpoint_test.exs`, `health_endpoint_test.exs`, `metrics_endpoint_test.exs`, `openapi_endpoint_test.exs`, `not_found_test.exs` |