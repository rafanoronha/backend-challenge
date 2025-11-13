# Infraestrutura AWS - Token Service

## Arquitetura

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

## Decisões Arquiteturais

### Região: us-east-1 (Norte da Virgínia)

**Razão:** Região mais econômica da AWS. Preços de Fargate ~47% menores que sa-east-1 (São Paulo).

### Single Availability Zone

**Razão:** Aplicação stateless sem banco de dados não requer multi-AZ. ALB distribui tráfego adequadamente mesmo com tasks em uma única AZ.

**Trade-off:** Alta disponibilidade reduzida, mas suficiente para demonstração e reduz complexidade operacional.

### Subnets Públicas (sem NAT Gateway)

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

### ECS Fargate vs EKS vs EC2

| Opção | Custo/mês | Razão |
|-------|-----------|-------|
| **ECS Fargate** | ~$29 | ✅ Escolhido - Serverless, zero overhead operacional |
| EKS | ~$73+ | ❌ Control plane fixo $73/mês + worker nodes |
| EC2 t3.micro | ~$8 | ❌ Requer gerenciamento manual, menos cloud-native |

### Compute: 0.25 vCPU / 0.5 GB RAM

**Razão:** Aplicação Elixir é extremamente leve (sem banco, sem I/O). Configuração mínima do Fargate é suficiente.

**Testes indicam:** ~50-100MB de memória em uso. BEAM VM usa recursos de forma eficiente.

### DNS: ALB público (sem Route53 customizado)

**Razão:** Economizar ~$0.50/mês + custo de domínio. ALB fornece DNS público funcional para demonstração.

**Formato:** `token-service-<hash>.us-east-1.elb.amazonaws.com`

### Observabilidade: CloudWatch nativo

**Razão:** Incluído no custo do ECS. Grafana/Prometheus requerem EC2 adicional (~$10-15/mês).

**Exposição:** Endpoint `/metrics` em formato Prometheus disponível para scraping futuro se necessário.

## Estimativa de Custos

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

## Recursos Provisionados

### Networking
- 1x VPC (10.0.0.0/16)
- 1x Internet Gateway
- 1x Subnet Pública (us-east-1a)
- 1x Route Table

### Compute
- 1x ECS Cluster
- 1x ECS Task Definition (Fargate)
- 1x ECS Service (desired: 1)

### Load Balancing
- 1x Application Load Balancer
- 1x Target Group (health check: `/health`)
- 1x Listener (HTTP:80)

### Security
- 2x Security Groups (ALB, ECS Tasks)
- 2x IAM Roles (Task Execution, Task)

### Container & Logs
- 1x ECR Repository (lifecycle: últimas 10 imagens)
- 1x CloudWatch Log Group (retention: 7 dias)

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

**Ambientes:**
- Production: Deploy automático na branch `main`

## Segurança

### Network Security
- ALB Security Group: Permite 0.0.0.0/0:80
- ECS Security Group: Permite APENAS ALB SG → 4000/tcp
- Egress: Permite todo tráfego saída (para pull de imagens ECR)

### Application Security
- Container roda como usuário não-root (`elixir:1000`)
- Imagem Alpine Linux minimizada
- Sem secrets em variáveis de ambiente (app não requer)

### IAM
- Task Execution Role: Permite apenas pull ECR + push CloudWatch Logs
- Task Role: Mínimo necessário (nenhuma permissão adicional requerida)

## Escalabilidade

**Auto-scaling configurado:**
- Min: 1 task
- Max: 3 tasks
- Trigger: CPU > 70%

**Capacidade estimada:**
- 1 task: ~1000 req/s
- 3 tasks: ~3000 req/s

Mais que suficiente para demonstração e validação técnica.

## Limitações Conhecidas

1. **Single AZ:** Falha em us-east-1a causa downtime
2. **HTTP apenas:** SSL/TLS não configurado (pode adicionar ACM gratuitamente)
3. **Sem WAF:** Proteção básica contra DDoS via ALB, mas sem WAF
4. **Logs retention:** 7 dias apenas (vs 30+ para produção)
5. **Sem backup:** Stateless, sem dados a fazer backup

## Evolução Futura

Para produção real, considerar:
- ✅ Multi-AZ (adicionar us-east-1b)
- ✅ ACM Certificate para HTTPS
- ✅ WAF para proteção avançada
- ✅ CloudWatch Alarms com SNS
- ✅ Route53 com domínio customizado
- ✅ VPC Endpoints para ECR (se mover para subnet privada)
- ✅ Fargate Spot para reduzir custos (~70% economia)

