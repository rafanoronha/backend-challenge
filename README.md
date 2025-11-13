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

## Infraestrutura

A aplicação está preparada para deploy automatizado na AWS usando **Terraform** e **GitHub Actions**.

### Arquitetura

```
┌──────────────────────────────────────────────────────────────────┐
│                         INTERNET                                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Application LB      │
              │  (Multi-AZ padrão)   │
              │                      │
              │  DNS: token-svc-xxx  │
              │  .us-east-1          │
              │  .elb.amazonaws.com  │
              │                      │
              │  Listener: HTTP:80   │
              │  Target: /health     │
              └──────────┬───────────┘
                         │
                         ▼
     ┌───────────────────────────────────────────────────────┐
     │  VPC (10.0.0.0/16) - us-east-1                        │
     │                                                        │
     │  ┌──────────────────────────────────────────────┐    │
     │  │  Internet Gateway                            │    │
     │  └──────────────────────────────────────────────┘    │
     │                                                        │
     │  ┌──────────────────────────────────────────────┐    │
     │  │  Subnet Pública - us-east-1a                 │    │
     │  │  CIDR: 10.0.1.0/24                           │    │
     │  │                                               │    │
     │  │  ┌────────────────────────────────────────┐  │    │
     │  │  │  ECS Fargate Task                      │  │    │
     │  │  │                                         │  │    │
     │  │  │  ┌──────────────────────────────────┐  │  │    │
     │  │  │  │  Token Service                   │  │  │    │
     │  │  │  │  - 0.25 vCPU / 0.5 GB RAM        │  │  │    │
     │  │  │  │  - Port: 4000                    │  │  │    │
     │  │  │  │  - Elixir 1.18 / OTP 27          │  │  │    │
     │  │  │  └──────────────────────────────────┘  │  │    │
     │  │  │                                         │  │    │
     │  │  │  Security Group:                       │  │    │
     │  │  │  IN:  ALB SG → 4000/tcp                │  │    │
     │  │  │  OUT: 0.0.0.0/0 → all                  │  │    │
     │  │  └────────────────────────────────────────┘  │    │
     │  └──────────────────────────────────────────────┘    │
     │                                                        │
     │  Route: 0.0.0.0/0 → IGW                               │
     └────────────────────────────────────────────────────────┘
                         │
                         ▼
     ┌────────────────────────────────────────────────────────┐
     │  AWS Services                                          │
     │                                                         │
     │  ┌────────────────┐    ┌──────────────────────────┐   │
     │  │  ECR           │    │  CloudWatch              │   │
     │  │  - Imagens     │    │  - Logs (JSON)           │   │
     │  │  - Lifecycle   │    │  - Métricas              │   │
     │  └────────────────┘    └──────────────────────────┘   │
     └─────────────────────────────────────────────────────────┘
```

### Decisões Arquiteturais

#### Região: us-east-1 (Norte da Virgínia)

**Razão:** Região mais econômica da AWS. Preços de Fargate ~47% menores que sa-east-1 (São Paulo).

#### Single Availability Zone

**Razão:** Aplicação stateless sem banco de dados não requer multi-AZ. ALB distribui tráfego adequadamente mesmo com tasks em uma única AZ.

**Trade-off:** Alta disponibilidade reduzida, mas suficiente para demonstração e reduz complexidade operacional.

#### Subnets Públicas (sem NAT Gateway)

**Razão:** Economia de ~$32/mês eliminando NAT Gateway desnecessário.

**Segurança:** Security Groups fornecem proteção equivalente para ingress traffic. Tasks só aceitam conexões do ALB na porta 4000.

**Quando subnet privada seria necessária:**
- Banco de dados (RDS) na arquitetura
- Requisitos de compliance (PCI-DSS, HIPAA)
- Necessidade de IP fixo de saída (Elastic IP via NAT)
- Aplicação com chamadas a APIs externas que validam por IP

**Nossa aplicação:**
- ✅ Stateless, sem dependências externas
- ✅ Sem armazenamento de dados sensíveis
- ✅ JWT validation totalmente local
- ✅ Sem chamadas a APIs externas

#### ECS Fargate vs EKS vs EC2

| Opção | Custo/mês | Razão |
|-------|-----------|-------|
| **ECS Fargate** | ~$29 | ✅ Escolhido - Serverless, zero overhead operacional |
| EKS | ~$73+ | ❌ Control plane fixo $73/mês + worker nodes |
| EC2 t3.micro | ~$8 | ❌ Requer gerenciamento manual, menos cloud-native |

#### Compute: 0.25 vCPU / 0.5 GB RAM

**Razão:** Aplicação Elixir é extremamente leve (sem banco, sem I/O). Configuração mínima do Fargate é suficiente.

**Testes indicam:** ~50-100MB de memória em uso. BEAM VM usa recursos de forma eficiente.

### Recursos Provisionados

**Networking:**
- 1x VPC (10.0.0.0/16)
- 1x Internet Gateway
- 2x Subnets Públicas (us-east-1a, us-east-1b - requisito do ALB)
- 1x Route Table

**Compute:**
- 1x ECS Cluster
- 1x ECS Task Definition (Fargate)
- 1x ECS Service (desired: 1, tasks apenas em us-east-1a)

**Load Balancing:**
- 1x Application Load Balancer
- 1x Target Group (health check: `/health`)
- 1x Listener (HTTP:80)

**Security:**
- 2x Security Groups (ALB, ECS Tasks)
- 2x IAM Roles (Task Execution, Task)

**Container & Logs:**
- 1x ECR Repository (lifecycle: últimas 10 imagens)
- 1x CloudWatch Log Group (retention: 7 dias)
- 1x S3 Bucket (Terraform state, versionado e criptografado)

### Estimativa de Custos

| Componente | Custo Semanal | Custo Mensal |
|------------|---------------|--------------|
| ECS Fargate (0.25 vCPU, 0.5GB) | $1.86 | $8.00 |
| Application Load Balancer | $3.72 | $16.00 |
| ECR (500MB storage) | $0.23 | $1.00 |
| CloudWatch Logs (1GB/semana) | $0.47 | $2.00 |
| Data Transfer (estimado) | $0.50 | $2.15 |
| **TOTAL** | **$6.78** | **$29.15** |

**Economia vs arquitetura tradicional:**
- Sem NAT Gateway: -$32/mês
- Sem EKS: -$73/mês
- Single AZ: -$8/mês (segunda task)

### CI/CD Pipeline

```
GitHub (push main) → GitHub Actions → Build Docker Image
                                            ↓
                                    Push to ECR
                                            ↓
                                   Update ECS Service
                                            ↓
                                   Health Check (/health)
                                            ↓
                                   Deploy Completo
```

**Continuous Integration (em PRs e pushes):**
- ✅ Executa testes automatizados
- ✅ Valida formatação de código
- ✅ Verifica build do Docker

**Continuous Deployment (apenas em `main`):**
- ✅ Provisiona/atualiza infraestrutura com Terraform
- ✅ Build da imagem Docker
- ✅ Push para Amazon ECR
- ✅ Deploy automático no ECS Fargate
- ✅ Health checks e rollout seguro
- ✅ Concurrency control (apenas 1 deploy por vez)

**Ambientes:**
- Production: Deploy automático na branch `main`

### Quick Start

1. **Configure AWS credentials no GitHub Secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. **Execute setup inicial do backend S3:**
   ```bash
   ./priv/scripts/infra/setup-aws-backend.sh
   ```

3. **Push para `main`:**
   ```bash
   git push origin main
   ```

4. **Aguarde o deploy automático via GitHub Actions**

**Documentação completa:** Ver [docs/AWS_DEPLOY.md](docs/AWS_DEPLOY.md)

### Scripts Auxiliares

```bash
# Build Docker local
./priv/scripts/infra/local-build.sh

# Verificar status do deployment
./priv/scripts/infra/check-deployment.sh

# Deploy manual (emergência)
./priv/scripts/infra/deploy-manual.sh
```

### Segurança

**Network Security:**
- ALB Security Group: Permite 0.0.0.0/0:80
- ECS Security Group: Permite APENAS ALB SG → 4000/tcp
- Egress: Permite todo tráfego saída (para pull de imagens ECR)

**Application Security:**
- Container roda como usuário não-root (`elixir:1000`)
- Imagem Debian minimizada
- Sem secrets em variáveis de ambiente (app não requer)

**IAM:**
- Task Execution Role: Permite apenas pull ECR + push CloudWatch Logs
- Task Role: Mínimo necessário (nenhuma permissão adicional requerida)

### Observabilidade

**CloudWatch Logs:**
- Formato JSON estruturado
- Retention: 7 dias
- Stream prefix: `ecs`

**CloudWatch Alarms:**
- CPU > 70%
- Memória > 80%
- Target unhealthy

**Métricas Prometheus:**
- Endpoint `/metrics` disponível para scraping futuro
- Pronto para integração com Grafana/Prometheus se necessário

### Escalabilidade

**Auto-scaling configurado:**
- Min: 1 task
- Max: 3 tasks
- Trigger: CPU > 70%

**Capacidade estimada:**
- 1 task: ~1000 req/s
- 3 tasks: ~3000 req/s

### Limitações Conhecidas

1. **Single AZ:** Falha em us-east-1a causa downtime
2. **HTTP apenas:** SSL/TLS não configurado (pode adicionar ACM gratuitamente)
3. **Sem WAF:** Proteção básica contra DDoS via ALB, mas sem WAF
4. **Logs retention:** 7 dias apenas (vs 30+ para produção)
5. **Sem backup:** Stateless, sem dados a fazer backup

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