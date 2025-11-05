#!/bin/bash
# Todo-Logger GitHub Deployment Script
# Installs GitHub CLI and deploys the repository

set -e  # Exit on error

echo "🚀 Todo-Logger GitHub 배포 스크립트"
echo "===================================="
echo ""

# Check if gh is already installed
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI가 이미 설치되어 있습니다."
    gh --version
else
    echo "📦 GitHub CLI 설치 중..."

    # Install GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt update
    sudo apt install gh -y

    echo "✅ GitHub CLI 설치 완료!"
    gh --version
fi

echo ""
echo "🔐 GitHub 인증 확인 중..."

# Check if already authenticated
if gh auth status &> /dev/null; then
    echo "✅ 이미 GitHub에 인증되어 있습니다."
else
    echo "❌ GitHub 인증이 필요합니다."
    echo ""
    echo "다음 명령어를 실행해주세요:"
    echo "  gh auth login"
    echo ""
    echo "브라우저에서 GitHub 계정으로 로그인하거나 토큰을 입력하세요."
    echo "인증 후 이 스크립트를 다시 실행해주세요."
    exit 1
fi

echo ""
echo "📂 Repository 생성 중..."

# Change to todo-logger directory
cd /home/jun/.claude/todo-logger

# Create repository
gh repo create todo-logger \
    --public \
    --source=. \
    --description="Persistent task history for AI-driven development with bilingual support (EN/KR)" \
    --remote=origin

echo "✅ Repository 생성 완료!"

echo ""
echo "⬆️  코드 푸시 중..."

# Push to GitHub
git push -u origin main

echo "✅ 푸시 완료!"

echo ""
echo "🏷️  Topics 추가 중..."

# Add topics
gh repo edit \
    --add-topic claude-code \
    --add-topic ai-assistant \
    --add-topic task-management \
    --add-topic productivity \
    --add-topic markdown \
    --add-topic bilingual \
    --add-topic developer-tools \
    --add-topic git-workflow \
    --add-topic korean

echo "✅ Topics 추가 완료!"

echo ""
echo "⚙️  Repository 기능 활성화 중..."

# Enable discussions
gh repo edit --enable-discussions

# Enable issues (default, but ensure it's on)
gh repo edit --enable-issues

# Enable wiki
gh repo edit --enable-wiki

echo "✅ Discussions, Issues, Wiki 활성화 완료!"

echo ""
echo "🎉 배포 완료!"
echo ""
echo "Repository URL:"
gh repo view --web --json url -q .url

echo ""
echo "다음 단계:"
echo "1. Repository 방문: https://github.com/$(gh api user -q .login)/todo-logger"
echo "2. Release 생성 (선택사항): gh release create v1.0.0"
echo "3. 소셜 미디어에 공유하기"
echo ""
echo "🌟 스타를 받을 준비 완료!"
