#!/bin/bash
set -e

# Script para build local do Docker

echo "🐳 Building Docker image locally..."

cd "$(dirname "$0")/../../.."

docker build -t token-service:local .

echo ""
echo "✅ Build concluído com sucesso!"
echo ""
echo "Para rodar localmente:"
echo "  docker run -p 4000:4000 token-service:local"
echo ""
echo "Testar:"
echo "  curl http://localhost:4000/health"
echo ""

