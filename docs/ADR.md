# Architecture Decision Records (ADR)

Este documento registra decisões arquiteturais importantes do projeto.

## Desenvolvimento

### ADR-001: Acelerar desenvolvimento com IA generativa

**Decisão:** Utilizar IA generativa para acelerar o desenvolvimento, com ênfase no Cursor usando modelo Sonnet 4.5.

**Contexto:**
- Requisitos funcionais simples
- Quantidade considerável de requisitos não funcionais
- Interesse em entregar em tempo hábil uma solução completa e bem documentada

**Justificativa:**
- Acelera escrita do código
- Reduz tempo em tarefas repetitivas (Terraform, CI/CD, scripts)
- Facilita criação de documentação técnica detalhada
- O Claude Sonnet 4.5 oferece desempenho superior em diversas áreas-chave, particularmente em fluxos de trabalho com agentes, codificação e uso geral de computadores.

**Trade-offs:**
- Código gerado requer revisão e validação

**Alternativas consideradas:**
- Desenvolvimento manual: Mais lento, mas maior controle total
- Modo automático do Cursor: Menor custo, mas menor desempenho

---

## Stack da Aplicação

### ADR-002: Linguagem Elixir

**Decisão:** Utilizar Elixir como linguagem de programação.

**Contexto:**
- Microsserviço HTTP para validação de tokens JWT
- Requisitos funcionais mínimos mas com necessidade de performance e confiabilidade

**Justificativa:**
- Elixir é uma linguagem funcional que permite código limpo e eficiente
- Excelente experiência de desenvolvimento: documentação completa, shell interativo útil

**Alternativas consideradas:**
- Qualquer linguagem de programação moderna.

---

### ADR-003: Stack Minimalista (Plug + Cowboy)

**Decisão:** Usar stack minimalista baseada em `plug_cowboy` em vez do framework Phoenix.

**Contexto:**
- Framework Phoenix é padrão na comunidade Elixir para aplicações web
- Microsserviço com requisitos funcionais mínimos

**Justificativa:**
- Stack minimalista tem mais aderência com características de um microserviço de backend
- Menos overhead
- Plug + Cowboy fornece tudo necessário: routing, middleware, servidor HTTP
- Facilita entendimento e manutenção do código

**Alternativas consideradas:**
- Phoenix: Framework completo, mas adiciona complexidade desnecessária para este caso

---

### ADR-004: Não Utilizar Padrões de Arquitetura

**Decisão:** Não aplicar Arquitetura Hexagonal ou Clean Architecture.

**Contexto:**
- Microsserviço com requisitos funcionais mínimos
- Apenas validação de tokens JWT

**Justificativa:**
- Seria "matar uma mosca com uma bazuca"
- Padrões complexos são úteis para microsserviços não triviais
- Para este caso, estrutura simples e direta é mais adequada
- Facilita leitura e manutenção do código

**Alternativas consideradas:**
- Arquitetura Hexagonal: Útil para sistemas complexos, desnecessário aqui
- Clean Architecture: Mesma justificativa

---

## Dependências

### ADR-005: Dependências do Projeto

| Dependência | Justificativa |
|-------------|---------------|
| `plug_cowboy` | Servidor HTTP e router. Stack minimalista sem Phoenix, usando Plug diretamente para endpoints REST |
| `joken` | Biblioteca para decodificação e validação de tokens JWT. Necessária para extrair e validar claims do token |
| `jason` | Encoder/decoder JSON. Usado para serialização de requisições e respostas da API |
| `ecto` | Validação de schemas. Utilizado para validação de claims JWT usando `Ecto.Schema` embedded (sem banco de dados) |
| `logger_json` | Logs estruturados em formato JSON. Essencial para observabilidade em produção, facilitando parsing e análise |
| `telemetry_metrics` | Sistema de métricas baseado em eventos. Framework para definir e coletar métricas customizadas |
| `telemetry_poller` | Polling de métricas da VM Erlang. Coleta métricas do sistema (memória, processos, filas) automaticamente |
| `telemetry_metrics_prometheus_core` | Exposição de métricas no formato Prometheus. Permite scraping via endpoint `/metrics` |
| `open_api_spex` | Especificação OpenAPI 3.0 e Swagger UI. Gera documentação interativa da API e validação de schemas |

---

## Infraestrutura AWS

### ADR-006: Região us-east-1 (Norte da Virgínia)

**Decisão:** Provisionar infraestrutura na região us-east-1.

**Justificativa:**
- Região mais econômica da AWS
- Preços de Fargate ~47% menores que sa-east-1 (São Paulo)
- Maior disponibilidade de serviços e features

**Alternativas consideradas:**
- sa-east-1 (São Paulo): Mais caro, mas menor latência para usuários brasileiros
- eu-west-1 (Irlanda): Preços intermediários, mas não necessário para este caso

---

### ADR-007: Single Availability Zone

**Decisão:** Executar ECS tasks em apenas uma AZ (us-east-1a).

**Justificativa:**
- Aplicação stateless sem banco de dados não requer multi-AZ
- ALB distribui tráfego adequadamente mesmo com tasks em uma única AZ
- Reduz complexidade operacional

**Trade-off:**
- Alta disponibilidade reduzida (falha em us-east-1a causa downtime)
- Suficiente para demonstração

**Alternativas consideradas:**
- Multi-AZ: Aumentaria custo e complexidade sem benefício significativo para este caso

---

### ADR-008: Subnets Públicas (sem NAT Gateway)

**Decisão:** Usar subnets públicas para ECS tasks, sem NAT Gateway.

**Justificativa:**
- Economia de ~$32/mês eliminando NAT Gateway desnecessário
- Security Groups fornecem proteção equivalente para ingress traffic
- Tasks só aceitam conexões do ALB na porta 4000

**Segurança:**
- ALB Security Group: Permite 0.0.0.0/0:80
- ECS Security Group: Permite APENAS ALB SG → 4000/tcp
- Tasks não são acessíveis diretamente da internet

**Cenário que justificaria subnet privada:**
- Banco de dados (RDS) na arquitetura
- Requisitos de compliance (PCI-DSS, HIPAA)
- Necessidade de IP fixo de saída (Elastic IP via NAT)
- Aplicação com chamadas a APIs externas que validam por IP

**Nosso cenário:**
- ✅ Stateless, sem dependências externas
- ✅ Sem armazenamento de dados sensíveis
- ✅ JWT validation totalmente local
- ✅ Sem chamadas a APIs externas

**Alternativas consideradas:**
- Subnets privadas + NAT Gateway: Mais seguro, mas ~$32/mês mais caro
- VPC Endpoints: Reduziria necessidade de NAT, mas ainda mais caro que necessário

---

### ADR-009: ECS Fargate vs EKS vs EC2

**Decisão:** Usar ECS Fargate para execução de containers.

| Opção | Custo/mês | Razão |
|-------|-----------|-------|
| **ECS Fargate** | ~$29 | ✅ Escolhido - Serverless, zero overhead operacional |
| EKS | ~$73+ | ❌ Control plane fixo $73/mês + worker nodes |
| EC2 t3.micro | ~$8 | ❌ Requer gerenciamento manual, menos cloud-native |

**Justificativa:**
- Serverless: zero gerenciamento de servidores
- Auto-scaling nativo
- Integração perfeita com ALB, CloudWatch, ECR
- Custo-benefício adequado para o caso de uso

**Alternativas consideradas:**
- EKS: Overhead de custo e complexidade desnecessário para 1 microserviço
- EC2: Requer gerenciamento manual, menos cloud-native

---

### ADR-010: Compute 0.25 vCPU / 0.5 GB RAM

**Decisão:** Configurar tasks Fargate com 0.25 vCPU e 0.5 GB RAM.

**Justificativa:**
- Aplicação Elixir é extremamente leve (sem banco, sem I/O)
- Configuração mínima do Fargate é suficiente
- Testes indicam: ~50-100MB de memória em uso
- BEAM VM usa recursos de forma eficiente

**Alternativas consideradas:**
- 0.5 vCPU / 1 GB: Mais recursos, mas desnecessário para este caso

---

### ADR-011: Sem WAF (Web Application Firewall)

**Decisão:** Não utilizar AWS WAF.

**Justificativa:**
- Economia de ~$5-10/mês
- AWS WAF tem custo por regra e por requisição processada

**Proteção atual:**
- ✅ ALB oferece proteção básica contra DDoS (AWS Shield Standard)
- ✅ Security Groups bloqueiam tráfego não autorizado
- ✅ Aplicação stateless sem vulnerabilidades SQL injection, XSS, etc.

**Cenário que justificaria WAF:**
- API pública com alto volume de tráfego malicioso
- Requisitos de compliance (OWASP Top 10, PCI-DSS)
- Proteção contra bots, scrapers e ataques automatizados
- Rate limiting avançado por IP/geolocalização

**Nosso cenário:**
- ✅ API simples (validação de JWT apenas)
- ✅ Sem parâmetros dinâmicos vulneráveis
- ✅ Demonstração (não produção crítica)
- ✅ ALB + Security Groups fornecem proteção adequada

**Alternativas consideradas:**
- AWS WAF: Adicionaria proteção extra, mas custo desnecessário para este caso

---

### ADR-012: DNS ALB Público (sem Route53 customizado)

**Decisão:** Usar DNS público do ALB, sem domínio customizado no Route53.

**Justificativa:**
- Economizar ~$0.50/mês + custo de domínio
- ALB fornece DNS público funcional para demonstração
- Formato: `token-service-<hash>.us-east-1.elb.amazonaws.com`

**Alternativas consideradas:**
- Route53 com domínio customizado: Mais profissional, mas custo adicional desnecessário

---

### ADR-013: Observabilidade CloudWatch Nativo

**Decisão:** Usar apenas CloudWatch para logs e métricas, sem Grafana/Prometheus dedicado.

**Justificativa:**
- CloudWatch incluído no custo do ECS
- Grafana/Prometheus requerem EC2 adicional (~$10-15/mês)
- Endpoint `/metrics` em formato Prometheus disponível para scraping futuro se necessário

**Alternativas consideradas:**
- Grafana + Prometheus: Mais features, mas custo adicional significativo

---

### ADR-014: Terraform State no S3 (sem DynamoDB)

**Decisão:** Usar S3 para Terraform state, sem DynamoDB para locking.

**Justificativa:**
- Economia de custo (DynamoDB free tier cobre, mas adiciona complexidade)
- GitHub Actions concurrency control garante execuções sequenciais
- Suficiente para este caso de uso

**Trade-off:**
- Sem locking automático via DynamoDB
- Depende de concurrency control do GitHub Actions

**Alternativas consideradas:**
- S3 + DynamoDB: Locking automático, mas complexidade adicional
- Terraform Cloud: Grátis, mas dependência de serviço externo

---

## CI/CD

### ADR-015: GitHub Actions para CI/CD

**Decisão:** Usar GitHub Actions para pipelines de CI/CD.

**Justificativa:**
- Integração nativa com GitHub
- Free tier generoso (2.000 min/mês para repositórios privados)
- Repositórios públicos têm minutos ilimitados
- Simples de configurar e manter

**Alternativas consideradas:**
- CircleCI: Boa opção, mas GitHub Actions é mais integrado
- GitLab CI: Similar, mas requer GitLab
- Jenkins: Requer servidor próprio, mais complexo

---

### ADR-016: Concurrency Control via GitHub Actions

**Decisão:** Usar concurrency groups do GitHub Actions em vez de DynamoDB para locking.

**Justificativa:**
- Zero custo adicional
- Nativo do GitHub Actions
- Garante apenas 1 deploy por vez
- Simples de configurar

**Trade-off:**
- Não protege contra execuções locais simultâneas
- Mas para este caso (deploy apenas via GitHub Actions), é suficiente

---

## Containerização

### ADR-017: Docker Multi-stage com Debian

**Decisão:** Usar Docker multi-stage build com Debian (não Alpine).

**Justificativa:**
- Debian evita problemas de DNS em produção
- Padrão da comunidade Elixir (Fly.io, Gigalixir)
- Multi-stage reduz tamanho da imagem final
- Usa `mix release` para criar artefato standalone

**Alternativas consideradas:**
- Alpine: Menor, mas problemas conhecidos com DNS em produção
- Ubuntu: Similar ao Debian, mas ligeiramente maior
