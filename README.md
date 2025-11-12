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

### Rodando as suítes de testes

O projeto possui uma suíte de testes abrangente com 60+ testes, incluindo [doctests](https://hexdocs.pm/elixir/docs-tests-and-with.html#doctests) e testes de integração

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