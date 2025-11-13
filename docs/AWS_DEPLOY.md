# Deploy AWS - Token Service

Guia completo para deploy da aplicação na AWS usando Terraform e GitHub Actions.

## Pré-requisitos

### 1. Ferramentas

- [AWS CLI](https://aws.amazon.com/cli/) configurado
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- Conta AWS com permissões de administrador
- Repositório no GitHub

### 2. Credenciais AWS

Configure suas credenciais localmente:

```bash
aws configure
```

Ou exporte as variáveis:

```bash
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## Setup Inicial

### Passo 1: Configurar Backend S3

O Terraform state será armazenado em S3. Execute o script de setup:

```bash
./priv/scripts/infra/setup-aws-backend.sh
```

Este script:
- ✅ Cria bucket S3 com versionamento
- ✅ Habilita criptografia AES256
- ✅ Bloqueia acesso público
- ✅ Migra state local para S3

**Saída esperada:**
```
✅ Backend S3 configurado com sucesso!
Bucket: token-service-terraform-state
```

### Passo 2: Configurar GitHub Secrets

No seu repositório GitHub, vá em **Settings → Secrets and variables → Actions** e adicione:

| Secret Name | Descrição | Como obter |
|-------------|-----------|------------|
| `AWS_ACCESS_KEY_ID` | Access Key da AWS | IAM → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | Secret Key da AWS | IAM → Users → Security credentials |

**Permissões necessárias para o usuário IAM:**
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonECS_FullAccess`
- `AmazonVPCFullAccess`
- `IAMFullAccess`
- `CloudWatchFullAccess`
- `AmazonS3FullAccess`

Ou use a policy customizada em `docs/iam-policy.json` (mais restritiva).

### Passo 3: Push para Main

```bash
git add .
git commit -m "feat(infra): initial infrastructure setup"
git push origin main
```

O GitHub Actions automaticamente:
1. ✅ Roda testes (CI workflow)
2. ✅ Provisiona infraestrutura Terraform
3. ✅ Faz build da imagem Docker
4. ✅ Push para ECR
5. ✅ Deploy no ECS Fargate

## Acompanhando o Deploy

### Via GitHub Actions

Vá em **Actions** no GitHub e acompanhe o workflow `Deploy`.

### Via AWS Console

1. **ECR:** Verificar se a imagem foi enviada
   - Console → ECR → Repositories → token-service

2. **ECS:** Verificar tasks rodando
   - Console → ECS → Clusters → token-service-cluster

3. **CloudWatch:** Ver logs em tempo real
   - Console → CloudWatch → Log groups → /ecs/token-service

### Via CLI

Verificar status do deployment:

```bash
./priv/scripts/infra/check-deployment.sh
```

Ver logs da aplicação:

```bash
aws logs tail /ecs/token-service --follow --region us-east-1
```

## Acessando a Aplicação

Após o deploy, obtenha a URL do Application Load Balancer:

```bash
cd terraform
terraform output alb_url
```

Ou via GitHub Actions (veja os logs do workflow).

### Testar endpoints

```bash
# Health check
curl http://TOKEN-SERVICE-ALB-URL/health

# Validate token
curl -X POST http://TOKEN-SERVICE-ALB-URL/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"}'

# Métricas Prometheus
curl http://TOKEN-SERVICE-ALB-URL/metrics
```

## Workflows CI/CD

### CI (Continuous Integration)

**Trigger:** Push em qualquer branch ou Pull Request

**Etapas:**
1. Run tests
2. Check formatting
3. Build Docker image (validação)

### Deploy (Continuous Deployment)

**Trigger:** Push na branch `main`

**Etapas:**
1. Terraform plan + apply
2. Build Docker image
3. Push para ECR
4. Update ECS service
5. Wait for stability

**Concurrency control:** Apenas 1 deploy por vez (evita race conditions no state).

## Estrutura da Infraestrutura

### Recursos Provisionados

| Recurso | Quantidade | Custo Estimado |
|---------|------------|----------------|
| VPC | 1 | Gratuito |
| Subnets públicas | 2 (us-east-1a, us-east-1b) | Gratuito |
| Internet Gateway | 1 | Gratuito |
| Application Load Balancer | 1 | ~$16/mês |
| ECS Fargate (0.25 vCPU, 0.5GB) | 1 task | ~$8/mês |
| ECR Repository | 1 | ~$1/mês |
| CloudWatch Logs | Retention 7 dias | ~$2/mês |
| S3 (Terraform state) | 1 bucket | ~$0.50/mês |
| **Total** | | **~$27.50/mês** |

### Arquitetura

```
Internet → ALB → ECS Fargate Task → CloudWatch
                      ↓
                    ECR (imagens)
```

- Tasks em **subnet pública** (sem NAT Gateway = economia)
- Security Group permite apenas ALB → Task:4000
- Auto-scaling: 1-3 tasks baseado em CPU

## Troubleshooting

### Deploy falhou no GitHub Actions

**Verificar:**
1. Secrets estão configurados corretamente
2. Usuário IAM tem permissões necessárias
3. Região está correta (us-east-1)

**Ver logs detalhados:**
- GitHub Actions → Workflow run → Job → Step

### Task não inicia no ECS

**Verificar:**
```bash
aws ecs describe-services \
  --cluster token-service-cluster \
  --services token-service-service \
  --region us-east-1
```

**Causas comuns:**
- Imagem não existe no ECR
- IAM role sem permissão de pull
- Subnet sem rota para Internet Gateway

### Health check falhando

**Verificar logs:**
```bash
aws logs tail /ecs/token-service --follow --region us-east-1
```

**Causas comuns:**
- Aplicação não iniciou (ver logs)
- Porta incorreta (deve ser 4000)
- Security Group bloqueando ALB → Task

### Terraform state locked

**Causa:** Outro workflow está executando ou foi interrompido.

**Solução:** Aguarde o workflow terminar ou cancele manualmente no GitHub Actions.

## Deploy Manual (Emergência)

Se GitHub Actions estiver indisponível:

```bash
./priv/scripts/infra/deploy-manual.sh
```

⚠️ **Atenção:** Bypassa concurrency control. Use apenas em emergências.

## Custos e Otimizações

### Custos Atuais (~$27.50/mês)

Para reduzir custos adicionalmente:

1. **Usar Fargate Spot** (~70% economia)
   ```hcl
   capacity_provider_strategy {
     capacity_provider = "FARGATE_SPOT"
     weight           = 100
   }
   ```

2. **Reduzir retention de logs** (7 → 3 dias)
   ```hcl
   retention_in_days = 3
   ```

3. **Desligar à noite** (se demo temporária)
   ```bash
   aws ecs update-service \
     --cluster token-service-cluster \
     --service token-service-service \
     --desired-count 0
   ```

### Free Tier (12 meses)

Se sua conta AWS tem < 12 meses:
- Fargate: 20GB storage gratuito/mês
- ALB: Parcialmente coberto
- **Custo real: ~$15-20/mês**

## Destruindo a Infraestrutura

Quando não precisar mais:

```bash
cd terraform
terraform destroy -auto-approve
```

**Atenção:** Isso remove TODOS os recursos (irreversível).

Para manter apenas o bucket S3 (state):
```bash
terraform destroy -target=aws_ecs_service.main -auto-approve
terraform destroy -target=aws_ecs_cluster.main -auto-approve
# ... e assim por diante
```

## Próximos Passos (Melhorias)

Para produção real, considere:

- [ ] Adicionar SSL/TLS (ACM + HTTPS listener)
- [ ] Route53 com domínio customizado
- [ ] WAF para proteção contra ataques
- [ ] CloudWatch Alarms com SNS (alertas por email)
- [ ] Multi-AZ para tasks (alta disponibilidade)
- [ ] CI/CD staging environment
- [ ] Secrets Manager para configurações sensíveis
- [ ] VPC Endpoints (se mover para subnets privadas)
- [ ] Container Insights detalhado
- [ ] Backup automatizado do state S3

## Referências

- [Documentação Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Fargate Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [GitHub Actions para AWS](https://github.com/aws-actions)

