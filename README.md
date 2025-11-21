# Token Service

Microsserviço HTTP para validação de tokens JWT conforme regras de negócio específicas.

O objetivo desse projeto é contemplar os requisitos descritos em [BACKEND-CHALLENGE.md](BACKEND-CHALLENGE.md).

## Registro de prompts com a IA

Os prompts utilizados para a IA acelerar a construção do projeto estão documentados em [docs/DEV_AI_PROMPTS.md](docs/DEV_AI_PROMPTS.md) e [docs/INFRA_AI_PROMPTS.md](docs/INFRA_AI_PROMPTS.md).

## Registro de decisões arquiteturais

Decisões arquiteturais importantes do projeto foram registradas em [docs/ADR.md](docs/ADR.md).


## Stack do projeto

- **Linguagem:** Elixir 1.18+ / Erlang OTP 27+
- **Framework:** Stack minimalista com Plug + Cowboy (sem Phoenix)
- **Padrões:** Estrutura simples, sem padrões como Hexagonal/Clean Architecture

## Ambiente produtivo

Acesse a aplicação na URL http://token-service-alb-793454956.us-east-1.elb.amazonaws.com.  
Ao fazer um `GET /` o servidor vai te redirecionar para `/swagger`.

## Swagger UI

Acesse a url `/swagger` para:
- Visualizar a especificação OpenAPI completa
- Testar a API diretamente pelo navegador com 3 exemplos prontos:
  - **Valid Token**: Token válido que atende todas as regras de negócio
  - **Invalid Claims**: JWT válido mas com Name contendo números
  - **Malformed JWT**: JWT com estrutura inválida
- Explorar os schemas de validação

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

# Iniciar o servidor
mix start
```

A aplicação estará disponível em [`http://localhost:4000`](http://localhost:4000).

**Endpoints disponíveis:**

- `GET /health` - Health check
- `POST /validate` - Valida um token JWT
- `GET /metrics` - Métricas Prometheus para observabilidade
- `GET /openapi` - Especificação OpenAPI 3.0 em JSON
- `GET /swagger` - Interface Swagger UI para explorar a API

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
- `http_request_count` - Total de requisições HTTP (tags: `method`, `path`)

**Métricas customizadas:**
- `token_service_validation_count` - Total de validações por resultado (tags: `result=success|failed`)
- `token_service_validation_failure_reasons` - Falhas por motivo (tags: `reason=invalid_jwt|invalid_claims`)

**Métricas de VM:**
- `vm_memory_total_bytes` - Memória total usada pela VM
- `vm_total_run_queue_lengths_total` - Tamanho das filas de execução
- `vm_system_counts_process_count` - Número de processos Erlang

## CI/CD Pipeline

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

#### Continuous Integration (em PRs e pushes)

Workflow **CI** do Github Actions
 
- ✅ Executa testes automatizados
- ✅ Valida formatação de código
- ✅ Verifica build do Docker

#### Continuous Deployment (apenas em `main`)

Workflow **Deploy** do Github Actions
- ✅ Provisiona/atualiza infraestrutura com Terraform
- ✅ Build da imagem Docker
- ✅ Push para Amazon ECR
- ✅ Deploy automático no ECS Fargate
- ✅ Health checks e rollout seguro
- ✅ Concurrency control (apenas 1 deploy por vez)

## Infraestrutura AWS

### Limitações Conhecidas

1. **Single AZ:** Falha em us-east-1a causa downtime
2. **HTTP apenas:** SSL/TLS não configurado (pode adicionar ACM gratuitamente)
3. **Sem WAF:** Proteção básica contra DDoS via ALB, mas sem WAF
4. **Logs retention:** 7 dias apenas (vs 30+ para produção)
5. **Sem backup:** Stateless, sem dados a fazer backup

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

### Infraestrutura

| Arquivo/Pasta | Descrição |
|---------------|-----------|
| `priv/terraform/` | Infraestrutura como código (IaC) para deploy na AWS usando Terraform |
| `priv/terraform/main.tf` | Configuração do provider AWS e backend S3 para Terraform state |
| `priv/terraform/vpc.tf` | VPC, subnets públicas, Internet Gateway e route tables |
| `priv/terraform/security_groups.tf` | Security Groups do ALB e ECS Tasks |
| `priv/terraform/iam.tf` | IAM Roles para ECS Task Execution e Task |
| `priv/terraform/alb.tf` | Application Load Balancer, target group e listener HTTP |
| `priv/terraform/ecr.tf` | ECR Repository para imagens Docker com lifecycle policy |
| `priv/terraform/ecs.tf` | ECS Cluster, Task Definition e Service (Fargate) |
| `priv/terraform/cloudwatch.tf` | CloudWatch Log Group e alarms (CPU, memória, health) |
| `priv/terraform/backend-setup.tf` | Provisiona S3 bucket para Terraform state remoto |

### Scripts

| Arquivo | Descrição |
|---------|-----------|
| `priv/scripts/infra/setup-aws-backend.sh` | Setup inicial do backend S3 para Terraform state |
| `priv/scripts/infra/local-build.sh` | Build da imagem Docker localmente para testes |
| `priv/scripts/infra/check-deployment.sh` | Verifica status do deployment e tasks rodando no ECS |

### CI/CD

| Arquivo | Descrição |
|---------|-----------|
| `.github/workflows/ci.yml` | Workflow de Continuous Integration - executa testes e validações em PRs e pushes |
| `.github/workflows/deploy.yml` | Workflow de Continuous Deployment - provisiona infra e faz deploy automático na branch `main` |