#!/bin/bash

# Atualizar o sistema
sudo yum update -y

# Instalar dependências necessárias
sudo yum install -y git curl wget

# Adicionar repositório do Docker (se necessário)
sudo yum install -y docker

# Iniciar o serviço do Docker
sudo systemctl start docker

# Habilitar Docker para iniciar automaticamente no boot
sudo systemctl enable docker

# Verificar status do Docker
sudo systemctl status docker

# Verificar versão do Docker instalada
docker --version

# (Opcional) Adicionar seu usuário ao grupo docker para não precisar usar sudo
sudo usermod -aG docker $USER

# Você precisa fazer logout e login novamente para que as permissões sejam aplicadas
# Ou execute este comando para aplicar as mudanças imediatamente:
newgrp docker

# Testar Docker com uma imagem simples
docker run hello-world

# (Opcional) Instalar Docker Compose
sudo yum install -y python3-pip
pip3 install docker-compose

# Verificar versão do Docker Compose
docker-compose --version
