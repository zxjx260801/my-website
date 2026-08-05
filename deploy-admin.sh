#!/bin/bash
# ==========================================
# 博客管理器部署脚本
# ==========================================
# 功能：将图形化管理器添加到 Hugo 站点
#       部署后访问 https://zxjx2681.com/admin/
# 用法：在 GitHub Codespaces 终端中运行
#       bash deploy-admin.sh
# ==========================================

set -e

# 安全检查
if [ ! -f "hugo.toml" ] && [ ! -f "config.toml" ]; then
  echo "❌ 请在 Hugo 项目根目录运行此脚本"
  exit 1
fi

echo "🚀 开始部署博客管理器..."

# 创建 static/admin 目录（Hugo 会原样输出到 public/admin/）
mkdir -p static/admin

echo "📁 目录已创建: static/admin/"

# 管理器 HTML 文件由本地复制到 Codespaces
# 如果你是通过拖拽上传 deploy-admin.sh 的，请确保也上传了 admin/index.html
if [ -f "admin/index.html" ]; then
  cp admin/index.html static/admin/index.html
  echo "📋 管理器页面已复制"
elif [ -f "static/admin/index.html" ]; then
  echo "✅ 管理器页面已存在"
else
  echo "⚠️  未找到 admin/index.html，请确保同时上传了该文件"
  exit 1
fi

echo ""
echo "========================================"
echo "✅ 管理器部署完成！"
echo "========================================"

# 自动提交并推送
if [ -d ".git" ]; then
  echo "🚀 自动提交并推送..."

  if [ -z "$(git config user.name)" ]; then
    git config user.name "zxjx260801"
    git config user.email "zxjx260801@users.noreply.github.com"
  fi

  git add -A

  if ! git diff --cached --quiet; then
    git commit -m "feat: 添加图形化博客管理器

- 在 /admin/ 路径添加管理界面
- 支持 GitHub API 直接管理文章
- 支持新建、编辑、删除文章
- 支持 Markdown 实时预览
- 支持分类、标签、草稿管理
- 支持站点设置（标题、简介、社交链接）"

    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    if git push origin "$CURRENT_BRANCH" 2>&1; then
      echo ""
      echo "🎉 推送成功！"
      echo "📱 约 1-2 分钟后访问: https://zxjx2681.com/admin/"
      echo ""
      echo "首次使用需要 GitHub Token，请访问:"
      echo "   https://github.com/settings/tokens/new?scopes=repo&description=博客管理器"
      echo "   勾选 repo 权限，生成后复制 Token"
    else
      echo "❌ 推送失败，请尝试: git pull --rebase origin main && git push"
    fi
  else
    echo "ℹ️  没有更改需要提交"
  fi
fi
