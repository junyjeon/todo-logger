#!/bin/bash
# Todo-Logger GitHub Deployment Script (Interactive)
# 브라우저 없이 토큰으로 인증 가능

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
    echo "인증 방법을 선택하세요:"
    echo "  1) 브라우저로 인증 (기본)"
    echo "  2) Personal Access Token으로 인증 (브라우저 불필요) ⭐"
    echo ""
    read -p "선택 (1 또는 2): " auth_choice

    if [ "$auth_choice" = "2" ]; then
        echo ""
        echo "📝 Personal Access Token 생성:"
        echo "  1. https://github.com/settings/tokens 접속"
        echo "  2. 'Generate new token (classic)' 클릭"
        echo "  3. 권한 선택: repo, workflow"
        echo "  4. 토큰 생성 후 복사"
        echo ""
        echo "토큰을 입력하고 Enter를 누르세요:"
        gh auth login --with-token
        echo "✅ 토큰 인증 완료!"
    else
        echo ""
        echo "브라우저가 열립니다..."
        gh auth login
        echo "✅ 브라우저 인증 완료!"
    fi
fi

echo ""
echo "📂 Repository 생성 중..."

# Change to todo-logger directory
cd /home/jun/.claude/todo-logger

# Check if repository already exists
if gh repo view todo-logger &> /dev/null; then
    echo "⚠️  Repository가 이미 존재합니다."
    echo "기존 repository를 사용합니다."
else
    # Create repository
    gh repo create todo-logger \
        --public \
        --source=. \
        --description="Persistent task history for AI-driven development with bilingual support (EN/KR)" \
        --remote=origin

    echo "✅ Repository 생성 완료!"
fi

echo ""
echo "⬆️  코드 푸시 중..."

# Push to GitHub
git push -u origin main 2>/dev/null || git push origin main

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

# Enable issues
gh repo edit --enable-issues

# Enable wiki
gh repo edit --enable-wiki

echo "✅ Discussions, Issues, Wiki 활성화 완료!"

echo ""
echo "🎉 배포 완료!"
echo ""
echo "📍 Repository URL:"
REPO_URL=$(gh repo view --json url -q .url)
echo "   $REPO_URL"

echo ""
echo "📱 다음 단계:"
echo "  1. Repository 확인: $REPO_URL"
echo "  2. Release 생성 (선택사항):"
echo "     gh release create v1.0.0 --title 'Todo-Logger v1.0.0' --notes '🎉 Initial release'"
echo "  3. 소셜 미디어에 공유하기"
echo ""
echo "🌟 스타를 받을 준비 완료!"
