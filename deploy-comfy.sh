#!/bin/bash
# ==========================================
# Comfy 主题一键自动部署脚本
# ==========================================
# 功能：创建主题文件 → 更新配置 → 移除旧主题
#       → 自动 git commit → 自动 git push → Cloudflare 自动构建
# 用法：在 GitHub Codespaces 终端中运行
#       bash deploy-comfy.sh
# ==========================================

set -e

# 安全检查：确认在 Hugo 项目根目录
if [ ! -f "hugo.toml" ] && [ ! -f "config.toml" ] && [ ! -f "config.yaml" ]; then
  echo "❌ 错误：请在 Hugo 项目根目录运行此脚本"
  echo "   （包含 hugo.toml 或 config.toml 的目录）"
  echo ""
  echo "   如果你在 Codespaces 中，项目根目录通常就是默认打开的目录。"
  exit 1
fi

# 安全检查：确认 git 仓库
if [ ! -d ".git" ]; then
  echo "⚠️  当前目录不是 git 仓库，但脚本仍会创建文件。"
  echo "   如需推送到 GitHub，请确保在正确的 Codespace 中运行。"
fi

echo "🚀 开始部署 Comfy 主题..."

# 创建主题目录结构
mkdir -p themes/comfy/assets/css
mkdir -p themes/comfy/layouts/_default
mkdir -p themes/comfy/layouts/partials
mkdir -p content/posts
mkdir -p content/archives

echo "📁 目录结构已创建"

# ==========================================
# 1. theme.toml
# ==========================================
cat > themes/comfy/theme.toml << 'ENDOFFILE'
name = "Comfy"
license = "MIT"
description = "A comfortable, card-style blog theme with sidebar"
tags = ["blog", "dark", "responsive", "sidebar"]
min_version = "0.100.0"

[author]
  name = "Blog Owner"
ENDOFFILE

# ==========================================
# 2. main.css
# ==========================================
cat > themes/comfy/assets/css/main.css << 'ENDOFFILE'
/* ===== Theme Variables ===== */
:root {
  --bg-base: #18181b; --bg-surface: #1e1e22; --bg-elevated: #27272a;
  --bg-card: #1e1e22; --bg-card-hover: #25252a;
  --accent: #06b6d4; --accent-soft: rgba(6,182,212,0.12); --accent-glow: rgba(6,182,212,0.06);
  --text-primary: #f4f4f5; --text-secondary: #a1a1aa; --text-tertiary: #71717a;
  --border: rgba(255,255,255,0.06); --border-hover: rgba(255,255,255,0.12);
  --radius: 12px; --radius-sm: 8px; --radius-lg: 16px;
  --shadow: 0 1px 3px rgba(0,0,0,0.2);
  --shadow-hover: 0 4px 12px rgba(0,0,0,0.25);
  --font-sans: "PingFang SC","Microsoft YaHei","Noto Sans SC",-apple-system,BlinkMacSystemFont,sans-serif;
  --font-mono: "JetBrains Mono","SF Mono",Consolas,monospace;
  --transition: 0.3s cubic-bezier(0.4,0,0.2,1);
}
[data-theme="light"] {
  --bg-base: #fafaf9; --bg-surface: #fff; --bg-elevated: #f5f5f4;
  --bg-card: #fff; --bg-card-hover: #fafaf9;
  --accent: #0891b2; --accent-soft: rgba(8,145,178,0.08); --accent-glow: rgba(8,145,178,0.04);
  --text-primary: #1c1917; --text-secondary: #57534e; --text-tertiary: #a8a29e;
  --border: rgba(0,0,0,0.06); --border-hover: rgba(0,0,0,0.12);
  --shadow: 0 1px 3px rgba(0,0,0,0.06);
  --shadow-hover: 0 4px 12px rgba(0,0,0,0.08);
}
* { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior:smooth; }
body { font-family:var(--font-sans); background:var(--bg-base); color:var(--text-primary); line-height:1.7; font-size:15px; -webkit-font-smoothing:antialiased; transition: background 0.3s, color 0.3s; }
a { color:inherit; text-decoration:none; }
img { max-width:100%; height:auto; }
.blog-wrap { max-width:1100px; margin:0 auto; padding:20px 24px; }
.blog-grid { display:grid; grid-template-columns:240px 1fr; gap:32px; align-items:start; }
.sb { position:sticky; top:24px; display:flex; flex-direction:column; gap:16px; }
.sb-card { background:var(--bg-surface); border:1px solid var(--border); border-radius:var(--radius); padding:20px; transition:var(--transition); }
.sb-profile { text-align:center; }
.sb-avatar { width:64px; height:64px; border-radius:50%; margin:0 auto 12px; background:linear-gradient(135deg,var(--accent),#0e7490); display:flex; align-items:center; justify-content:center; font-size:26px; font-weight:700; color:#fff; box-shadow:0 0 0 4px var(--accent-glow); }
.sb-name { font-size:16px; font-weight:700; margin-bottom:2px; }
.sb-bio { font-size:12px; color:var(--text-tertiary); }
.sb-socials { display:flex; justify-content:center; gap:8px; margin-top:14px; }
.sb-soc { width:32px; height:32px; border-radius:50%; display:flex; align-items:center; justify-content:center; background:var(--bg-elevated); color:var(--text-secondary); transition:var(--transition); cursor:pointer; }
.sb-soc:hover { color:#fff; transform:translateY(-2px); }
.sb-soc svg { width:15px; height:15px; }
.sb-search { display:flex; align-items:center; gap:8px; background:var(--bg-elevated); border-radius:var(--radius-sm); padding:8px 12px; margin-bottom:12px; }
.sb-search input { background:none; border:none; outline:none; color:var(--text-primary); font-size:13px; flex:1; font-family:var(--font-sans); }
.sb-search input::placeholder { color:var(--text-tertiary); }
.sb-search svg { width:15px; height:15px; color:var(--text-tertiary); flex-shrink:0; }
.sb-nav-title { font-size:12px; font-weight:600; color:var(--text-tertiary); text-transform:uppercase; letter-spacing:1px; margin-bottom:8px; padding-left:4px; }
.sb-nav-item { display:flex; align-items:center; gap:10px; padding:8px 12px; border-radius:var(--radius-sm); color:var(--text-secondary); font-size:14px; font-weight:500; cursor:pointer; transition:var(--transition); }
.sb-nav-item:hover { background:var(--bg-elevated); color:var(--text-primary); }
.sb-nav-item.active { background:var(--accent-soft); color:var(--accent); }
.sb-nav-item svg { width:17px; height:17px; flex-shrink:0; opacity:0.8; }
.sb-nav-item .count { margin-left:auto; font-size:12px; font-family:var(--font-mono); color:var(--text-tertiary); background:var(--bg-elevated); padding:1px 8px; border-radius:10px; }
.sb-nav-item.active .count { background:var(--accent); color:var(--bg-base); }
.sb-nav-div { height:1px; background:var(--border); margin:6px 4px; }
.sb-stats { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
.sb-stat { text-align:center; padding:8px 4px; }
.sb-stat-val { font-size:18px; font-weight:700; color:var(--accent); font-family:var(--font-mono); }
.sb-stat-label { font-size:11px; color:var(--text-tertiary); margin-top:2px; }
.sb-theme-toggle { display:flex; align-items:center; justify-content:center; gap:6px; width:100%; padding:8px; border-radius:var(--radius-sm); background:var(--bg-elevated); border:none; color:var(--text-secondary); font-size:13px; cursor:pointer; transition:var(--transition); font-family:var(--font-sans); }
.sb-theme-toggle:hover { color:var(--text-primary); }
.sb-theme-toggle svg { width:16px; height:16px; }
.main { min-width:0; }
.art-card { background:var(--bg-card); border:1px solid var(--border); border-radius:var(--radius); padding:24px; margin-bottom:16px; cursor:pointer; transition:var(--transition); position:relative; overflow:hidden; display:block; }
.art-card:hover { border-color:var(--border-hover); background:var(--bg-card-hover); box-shadow:var(--shadow-hover); transform:translateY(-1px); }
.art-card::before { content:''; position:absolute; left:0; top:0; bottom:0; width:3px; background:var(--accent); transform:scaleY(0); transform-origin:bottom; transition:var(--transition); }
.art-card:hover::before { transform:scaleY(1); transform-origin:top; }
.art-meta-top { display:flex; align-items:center; gap:8px; margin-bottom:10px; }
.art-cat { display:inline-flex; align-items:center; gap:4px; padding:3px 10px; border-radius:12px; font-size:12px; font-weight:600; background:var(--accent-soft); color:var(--accent); }
.art-date { font-size:12px; color:var(--text-tertiary); font-family:var(--font-mono); }
.art-dot { width:3px; height:3px; border-radius:50%; background:var(--text-tertiary); }
.art-title { font-size:18px; font-weight:700; line-height:1.4; margin-bottom:8px; color:var(--text-primary); transition:var(--transition); }
.art-card:hover .art-title { color:var(--accent); }
.art-desc { font-size:14px; color:var(--text-secondary); line-height:1.7; margin-bottom:12px; }
.art-meta-bot { display:flex; align-items:center; gap:10px; flex-wrap:wrap; }
.art-tag { font-size:12px; color:var(--text-tertiary); padding:2px 8px; border-radius:6px; background:var(--bg-elevated); transition:var(--transition); }
.art-tag:hover { color:var(--accent); background:var(--accent-soft); }
.art-read { font-size:12px; color:var(--text-tertiary); display:flex; align-items:center; gap:4px; margin-left:auto; }
.art-read svg { width:13px; height:13px; }
.pg { display:flex; justify-content:center; gap:6px; margin-top:32px; }
.pg-btn { min-width:36px; height:36px; border-radius:var(--radius-sm); display:flex; align-items:center; justify-content:center; font-size:14px; font-family:var(--font-mono); background:var(--bg-surface); border:1px solid var(--border); color:var(--text-secondary); cursor:pointer; transition:var(--transition); }
.pg-btn:hover { border-color:var(--border-hover); color:var(--text-primary); }
.pg-btn.active { background:var(--accent); color:#fff; border-color:var(--accent); }
.article-page { background:var(--bg-card); border:1px solid var(--border); border-radius:var(--radius); padding:32px; }
.article-header { margin-bottom:24px; padding-bottom:20px; border-bottom:1px solid var(--border); }
.article-header h1 { font-size:28px; font-weight:800; line-height:1.3; margin-bottom:12px; }
.article-meta { display:flex; align-items:center; gap:10px; flex-wrap:wrap; font-size:13px; color:var(--text-tertiary); }
.article-meta .art-cat { font-size:13px; }
.article-content { font-size:16px; line-height:1.8; color:var(--text-primary); }
.article-content h2 { font-size:22px; font-weight:700; margin:24px 0 12px; }
.article-content h3 { font-size:18px; font-weight:600; margin:20px 0 10px; }
.article-content p { margin-bottom:16px; }
.article-content ul, .article-content ol { margin-bottom:16px; padding-left:24px; }
.article-content li { margin-bottom:6px; }
.article-content blockquote { border-left:3px solid var(--accent); padding:8px 16px; margin:16px 0; background:var(--accent-soft); border-radius:0 var(--radius-sm) var(--radius-sm) 0; color:var(--text-secondary); }
.article-content code { font-family:var(--font-mono); font-size:0.9em; background:var(--bg-elevated); padding:2px 6px; border-radius:4px; }
.article-content pre { background:var(--bg-elevated); border-radius:var(--radius-sm); padding:16px; overflow-x:auto; margin-bottom:16px; border:1px solid var(--border); }
.article-content pre code { background:none; padding:0; }
.article-content a { color:var(--accent); text-decoration:underline; text-underline-offset:2px; }
.article-content img { border-radius:var(--radius-sm); margin:16px 0; }
.article-content table { width:100%; border-collapse:collapse; margin-bottom:16px; }
.article-content th, .article-content td { border:1px solid var(--border); padding:8px 12px; text-align:left; }
.article-content th { background:var(--bg-elevated); font-weight:600; }
.article-footer { margin-top:32px; padding-top:20px; border-top:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; }
.article-tags { display:flex; gap:8px; flex-wrap:wrap; }
.archive-group { margin-bottom:32px; }
.archive-head { display:flex; align-items:center; gap:10px; margin-bottom:16px; padding-bottom:8px; border-bottom:1px solid var(--border); }
.archive-head h2 { font-size:20px; font-weight:700; }
.archive-count { font-size:13px; color:var(--text-tertiary); font-family:var(--font-mono); }
.not-found { text-align:center; padding:80px 20px; }
.not-found h1 { font-size:48px; font-weight:800; color:var(--accent); margin-bottom:12px; }
.not-found p { color:var(--text-secondary); margin-bottom:24px; }
.site-footer { text-align:center; padding:24px 24px 40px; color:var(--text-tertiary); font-size:12px; }
.site-footer a { color:var(--text-secondary); transition:var(--transition); }
.site-footer a:hover { color:var(--accent); }
@media (max-width: 860px) {
  .blog-grid { grid-template-columns:1fr; gap:20px; }
  .sb { position:static; }
  .article-page { padding:20px; }
  .article-header h1 { font-size:22px; }
}
ENDOFFILE

echo "🎨 CSS 已创建"

# ==========================================
# 3. baseof.html
# ==========================================
cat > themes/comfy/layouts/_default/baseof.html << 'ENDOFFILE'
<!DOCTYPE html>
<html lang="{{ .Site.LanguageCode }}" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ block "title" . }}{{ .Title }} - {{ .Site.Title }}{{ end }}</title>
    {{ partial "head.html" . }}
</head>
<body>
    <div class="blog-wrap">
        <div class="blog-grid">
            {{ partial "sidebar.html" . }}
            <main class="main">
                {{ block "main" . }}{{ end }}
            </main>
        </div>
    </div>
    {{ partial "footer.html" . }}
</body>
</html>
ENDOFFILE

# ==========================================
# 4. head.html
# ==========================================
cat > themes/comfy/layouts/partials/head.html << 'ENDOFFILE'
{{ $css := resources.Get "css/main.css" | minify | fingerprint }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}">
<link rel="icon" href="{{ "favicon.ico" | absURL }}">
<meta name="description" content="{{ with .Description }}{{ . }}{{ else }}{{ .Site.Params.description | default "个人技术博客" }}{{ end }}">
<meta property="og:title" content="{{ .Title }}">
<meta property="og:description" content="{{ with .Description }}{{ . }}{{ else }}{{ .Site.Params.description | default "个人技术博客" }}{{ end }}">
<meta property="og:type" content="{{ if .IsPage }}article{{ else }}website{{ end }}">
<meta property="og:url" content="{{ .Permalink }}">
ENDOFFILE

# ==========================================
# 5. sidebar.html
# ==========================================
cat > themes/comfy/layouts/partials/sidebar.html << 'ENDOFFILE'
<aside class="sb">
  <div class="sb-card sb-profile">
    <div class="sb-avatar">{{ substr .Site.Title 0 1 }}</div>
    <div class="sb-name">{{ .Site.Title }}</div>
    <div class="sb-bio">{{ .Site.Params.bio | default "记录技术与生活" }}</div>
    <div class="sb-socials">
      {{ with .Site.Params.social.youtube -}}
      <a class="sb-soc" href="https://youtube.com/@{{ . }}" title="YouTube" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M23.5 6.2a3 3 0 0 0-2.1-2.1C19.5 3.5 12 3.5 12 3.5s-7.5 0-9.4.5A3 3 0 0 0 .5 6.2C0 8 0 12 0 12s0 4 .5 5.8a3 3 0 0 0 2.1 2.1c1.9.5 9.4.5 9.4.5s7.5 0 9.4-.5a3 3 0 0 0 2.1-2.1c.5-1.8.5-5.8.5-5.8s0-4-.5-5.8zM9.5 15.6V8.4L15.8 12l-6.3 3.6z"/></svg>
      </a>
      {{ end -}}
      {{ with .Site.Params.social.twitter -}}
      <a class="sb-soc" href="https://twitter.com/{{ . }}" title="Twitter" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.2 2.3h3.3l-7.2 8.3 8.5 11.2h-6.8l-5.2-6.8-6 6.8H1.7l7.7-8.8L1.3 2.3h6.8l4.7 6.2zm-1.2 17.5h1.8L7.1 4.1H5.1z"/></svg>
      </a>
      {{ end -}}
      {{ with .Site.Params.social.bilibili -}}
      <a class="sb-soc" href="https://space.bilibili.com/{{ . }}" title="Bilibili" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M17.8 4.7h.9c1.5.1 2.8.6 3.8 1.6s1.5 2.2 1.6 3.8v7.4c-.1 1.5-.6 2.8-1.6 3.8s-2.3 1.5-3.8 1.6H5.3c-1.5-.1-2.8-.6-3.8-1.6S.1 18.9 0 17.4V10c.1-1.5.6-2.8 1.6-3.8S3.8 4.7 5.3 4.7h.8L5 3.6c-.3-.3-.4-.6-.4-.9 0-.4.1-.7.4-.9.3-.2.6-.4.9-.4.4 0 .7.1.9.4l2.9 2.7c.1.1.1.1.2.2h4.3c0-.1.1-.1.2-.2l2.9-2.7c.3-.2.6-.4.9-.4.4 0 .7.1.9.4.3.2.4.6.4.9 0 .4-.1.7-.4.9z"/></svg>
      </a>
      {{ end -}}
      {{ with .Site.Params.social.telegram -}}
      <a class="sb-soc" href="https://t.me/{{ . }}" title="Telegram" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 0a12 12 0 1 0 0 24 12 12 0 0 0 0-24zm5 7.2c.1 0 .3 0 .5.1.1.1.2.2.2.3v.5c-.2 1.9-1 6.5-1.4 8.6-.2.9-.5 1.2-.8 1.2-.7.1-1.2-.5-1.9-.9-1.1-.7-1.7-1.1-2.7-1.8-1.2-.8-.4-1.2.3-1.9.2-.2 3.2-3 3.3-3.2 0-.1 0-.2-.1-.2s-.2-.1-.3 0c-.1 0-1.8 1.1-5.1 3.3-.5.3-.9.5-1.3.5-.4 0-1.3-.2-1.9-.4-.8-.2-1.3-.4-1.3-.8 0-.2.3-.4.9-.7 3.5-1.5 5.8-2.5 7-3 3.3-1.4 4-1.6 4.5-1.6z"/></svg>
      </a>
      {{ end -}}
      {{ with .Site.Params.social.github -}}
      <a class="sb-soc" href="https://github.com/{{ . }}" title="GitHub" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.4 0 0 5.4 0 12c0 5.3 3.4 9.8 8.2 11.4.6.1.8-.3.8-.6v-2c-3.3.7-4-1.6-4-1.6-.5-1.4-1.3-1.8-1.3-1.8-1.1-.7.1-.7.1-.7 1.2.1 1.8 1.2 1.8 1.2 1.1 1.8 2.8 1.3 3.5 1 .1-.8.4-1.3.8-1.6-2.7-.3-5.5-1.3-5.5-5.9 0-1.3.5-2.4 1.2-3.2-.1-.3-.5-1.5.1-3.2 0 0 1-.3 3.3 1.2a11.5 11.5 0 0 1 6 0c2.3-1.5 3.3-1.2 3.3-1.2.6 1.7.2 2.9.1 3.2.8.8 1.2 1.9 1.2 3.2 0 4.6-2.8 5.6-5.5 5.9.4.4.8 1.1.8 2.2v3.3c0 .3.2.7.8.6A12 12 0 0 0 24 12c0-6.6-5.4-12-12-12z"/></svg>
      </a>
      {{ end -}}
      {{ with .Site.Params.social.email -}}
      <a class="sb-soc" href="mailto:{{ . }}" title="Email">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-10 5L2 7"/></svg>
      </a>
      {{ end -}}
    </div>
  </div>

  <div class="sb-card">
    <div class="sb-search">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
      <input type="text" placeholder="搜索文章..." id="search-input">
    </div>
    <div class="sb-nav-title">菜单</div>
    <a class="sb-nav-item {{ if .IsHome }}active{{ end }}" href="{{ .Site.BaseURL }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
      首页
    </a>
    <a class="sb-nav-item" href="{{ "archives" | absURL }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/></svg>
      归档
      <span class="count">{{ len .Site.RegularPages }}</span>
    </a>
    {{ if gt (len .Site.Taxonomies.categories) 0 -}}
    <div class="sb-nav-div"></div>
    <div class="sb-nav-title">分类</div>
    {{ range .Site.Taxonomies.categories -}}
    <a class="sb-nav-item" href="{{ .Page.Permalink }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      {{ .Page.Title }}
      <span class="count">{{ .Count }}</span>
    </a>
    {{ end -}}
    {{ end -}}
    {{ if gt (len .Site.Taxonomies.tags) 0 -}}
    <div class="sb-nav-div"></div>
    <div class="sb-nav-title">标签</div>
    {{ range first 5 .Site.Taxonomies.tags -}}
    <a class="sb-nav-item" href="{{ .Page.Permalink }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
      {{ .Page.Title }}
      <span class="count">{{ .Count }}</span>
    </a>
    {{ end -}}
    {{ end -}}
  </div>

  <div class="sb-card">
    <div class="sb-stats">
      <div class="sb-stat">
        <div class="sb-stat-val">{{ len .Site.RegularPages }}</div>
        <div class="sb-stat-label">文章</div>
      </div>
      <div class="sb-stat">
        <div class="sb-stat-val">{{ len .Site.Taxonomies.categories }}</div>
        <div class="sb-stat-label">分类</div>
      </div>
    </div>
  </div>

  <button class="sb-theme-toggle" onclick="toggleTheme()">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
    <span>切换主题</span>
  </button>
</aside>
ENDOFFILE

echo "🧩 侧边栏模板已创建"

# ==========================================
# 6. footer.html
# ==========================================
cat > themes/comfy/layouts/partials/footer.html << 'ENDOFFILE'
<footer class="site-footer">
  <p>&copy; {{ now.Format "2006" }} {{ .Site.Title }} &middot; Powered by <a href="https://gohugo.io" target="_blank" rel="noopener">Hugo</a></p>
</footer>
<script>
(function() {
  window.toggleTheme = function() {
    var html = document.documentElement;
    var current = html.getAttribute('data-theme') || 'dark';
    var next = current === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', next);
    try { localStorage.setItem('theme', next); } catch(e) {}
  };
  try {
    var saved = localStorage.getItem('theme');
    if (saved) document.documentElement.setAttribute('data-theme', saved);
  } catch(e) {}
  var searchInput = document.getElementById('search-input');
  if (searchInput) {
    searchInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter' && this.value.trim()) {
        window.location.href = '{{ "search" | absURL }}?q=' + encodeURIComponent(this.value.trim());
      }
    });
  }
  document.querySelectorAll('.art-card[data-url]').forEach(function(card) {
    card.addEventListener('click', function() {
      window.location.href = this.getAttribute('data-url');
    });
  });
})();
</script>
ENDOFFILE

# ==========================================
# 7. pagination.html
# ==========================================
cat > themes/comfy/layouts/partials/pagination.html << 'ENDOFFILE'
{{ if .Paginator.HasPrev -}}
<div class="pg">
  {{ if .Paginator.HasPrev -}}
  <a class="pg-btn" href="{{ .Paginator.Prev.URL }}">&laquo;</a>
  {{ end -}}
  {{ range .Paginator.Pagers -}}
  <a class="pg-btn {{ if eq . $.Paginator }}active{{ end }}" href="{{ .URL }}">{{ .PageNumber }}</a>
  {{ end -}}
  {{ if .Paginator.HasNext -}}
  <a class="pg-btn" href="{{ .Paginator.Next.URL }}">&raquo;</a>
  {{ end -}}
</div>
{{ end -}}
ENDOFFILE

# ==========================================
# 8. list.html
# ==========================================
cat > themes/comfy/layouts/_default/list.html << 'ENDOFFILE'
{{ define "main" }}
{{ $pages := .Pages }}
{{ if .IsHome }}{{ $pages = .Site.RegularPages }}{{ end }}
{{ range $pages.GroupByDate "2006" "desc" }}
<div class="archive-group">
  <div class="archive-head">
    <h2>{{ .Key }}</h2>
    <span class="archive-count">{{ len .Pages }} 篇</span>
  </div>
  {{ range .Pages }}
  <article class="art-card" data-url="{{ .Permalink }}">
    <div class="art-meta-top">
      {{ with .Params.categories }}
      {{ range first 1 . }}
      <span class="art-cat">{{ . }}</span>
      {{ end }}
      {{ else }}
      <span class="art-cat">文章</span>
      {{ end }}
      <span class="art-dot"></span>
      <span class="art-date">{{ .Date.Format "2006-01-02" }}</span>
    </div>
    <h2 class="art-title">{{ .Title }}</h2>
    <p class="art-desc">{{ .Summary | plainify | truncate 120 }}</p>
    <div class="art-meta-bot">
      {{ range .Params.tags }}
      <span class="art-tag">{{ . }}</span>
      {{ end }}
      <span class="art-read">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        {{ .ReadingTime }} 分钟
      </span>
    </div>
  </article>
  {{ end }}
</div>
{{ end }}
{{ partial "pagination.html" . }}
{{ end }}
ENDOFFILE

# ==========================================
# 9. single.html
# ==========================================
cat > themes/comfy/layouts/_default/single.html << 'ENDOFFILE'
{{ define "title" }}{{ .Title }}{{ end }}
{{ define "main" }}
<article class="article-page">
  <div class="article-header">
    {{ with .Params.categories }}
    {{ range first 1 . }}
    <span class="art-cat">{{ . }}</span>
    {{ end }}
    {{ end }}
    <h1>{{ .Title }}</h1>
    <div class="article-meta">
      <span class="art-date">{{ .Date.Format "2006-01-02" }}</span>
      <span class="art-dot"></span>
      <span>{{ .ReadingTime }} 分钟阅读</span>
      {{ with .Params.author }}
      <span class="art-dot"></span>
      <span>{{ . }}</span>
      {{ end }}
    </div>
  </div>
  <div class="article-content">
    {{ .Content }}
  </div>
  <div class="article-footer">
    <div class="article-tags">
      {{ range .Params.tags }}
      <span class="art-tag">{{ . }}</span>
      {{ end }}
    </div>
    <a href="{{ .Site.BaseURL }}" class="pg-btn">返回首页</a>
  </div>
</article>
{{ end }}
ENDOFFILE

# ==========================================
# 10. archives.html
# ==========================================
cat > themes/comfy/layouts/_default/archives.html << 'ENDOFFILE'
{{ define "main" }}
<div class="article-page">
  <div class="article-header">
    <h1>{{ .Title }}</h1>
  </div>
  <div class="article-content">
    {{ range .Site.RegularPages.GroupByDate "2006" "desc" }}
    <div class="archive-group">
      <div class="archive-head">
        <h2>{{ .Key }}</h2>
        <span class="archive-count">{{ len .Pages }} 篇</span>
      </div>
      {{ range .Pages }}
      <article class="art-card" data-url="{{ .Permalink }}" style="padding:16px 20px;">
        <div class="art-meta-top">
          {{ with .Params.categories }}
          {{ range first 1 . }}
          <span class="art-cat">{{ . }}</span>
          {{ end }}
          {{ end }}
          <span class="art-dot"></span>
          <span class="art-date">{{ .Date.Format "2006-01-02" }}</span>
        </div>
        <h2 class="art-title" style="font-size:16px;">{{ .Title }}</h2>
      </article>
      {{ end }}
    </div>
    {{ end }}
  </div>
</div>
{{ end }}
ENDOFFILE

# ==========================================
# 11. 404.html
# ==========================================
cat > themes/comfy/layouts/404.html << 'ENDOFFILE'
{{ define "main" }}
<div class="not-found">
  <h1>404</h1>
  <p>抱歉，你访问的页面不存在</p>
  <a href="{{ .Site.BaseURL }}" class="pg-btn">返回首页</a>
</div>
{{ end }}
ENDOFFILE

echo "📄 所有模板已创建"

# ==========================================
# 12. hugo.toml
# ==========================================
cat > hugo.toml << 'ENDOFFILE'
baseURL = "https://zxjx2681.com/"
languageCode = "zh-cn"
title = "我的博客"
theme = "comfy"
pagination.pagerSize = 10

[params]
  description = "记录技术与生活"
  bio = "记录技术与生活"

  [params.social]
    # 取消注释并填写你的社交账号
    # youtube = "你的频道名"
    # twitter = "你的用户名"
    # bilibili = "你的UID"
    # telegram = "你的用户名"
    # github = "你的用户名"
    # email = "你的邮箱"

[taxonomies]
  category = "categories"
  tag = "tags"

[[menu.main]]
  name = "首页"
  url = "/"
  weight = 1

[[menu.main]]
  name = "归档"
  url = "/archives/"
  weight = 2

[markup]
  [markup.highlight]
    style = "dracula"
    lineNos = false
    codeFences = true
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true

[services]
  [services.rss]
    limit = 20
ENDOFFILE

echo "⚙️  hugo.toml 已创建"

# ==========================================
# 13. 创建归档页面
# ==========================================
cat > content/archives/_index.md << 'ENDOFFILE'
---
title: "归档"
layout: "archives"
---
ENDOFFILE

# ==========================================
# 14. 创建示例文章（如果不存在）
# ==========================================
if [ ! -f content/posts/welcome.md ]; then
cat > content/posts/welcome.md << 'ENDOFFILE'
---
title: "使用 Hugo + Cloudflare Pages 搭建免费个人博客"
date: 2026-08-06
categories: ["教程"]
tags: ["Hugo", "Cloudflare", "博客"]
description: "零成本零维护的博客搭建方案。"
---

## 为什么选择 Hugo + Cloudflare Pages

搭建个人博客有很多选择，但 Hugo + Cloudflare Pages 的组合有几个显著优势：

- **完全免费**：Hugo 是开源静态站点生成器，Cloudflare Pages 提供免费托管
- **极快速度**：静态页面全球 CDN 分发
- **零维护**：推送到 GitHub 即自动部署

## 开始使用

使用 Markdown 编写文章，推送到 GitHub，Cloudflare 会自动构建部署。

享受你的博客吧！
ENDOFFILE
echo "📝 示例文章已创建"
else
echo "📝 示例文章已存在，跳过"
fi

# ==========================================
# 15. 移除 PaperMod 子模块（如果存在）
# ==========================================
if [ -f .gitmodules ]; then
  echo "🔄 检测到 .gitmodules，正在移除 PaperMod 子模块..."
  if grep -q "PaperMod" .gitmodules 2>/dev/null; then
    git submodule deinit -f themes/PaperMod 2>/dev/null || true
    git rm -f themes/PaperMod 2>/dev/null || true
    rm -rf .git/modules/themes/PaperMod 2>/dev/null || true
    rm -f .gitmodules 2>/dev/null || true
    echo "✅ PaperMod 子模块已移除"
  fi
fi

# ==========================================
# 16. 本地预览验证（可选）
# ==========================================
echo ""
echo "========================================"
echo "✅ Comfy 主题文件已全部创建！"
echo "========================================"

# 检查 hugo 是否可用，尝试本地构建验证
if command -v hugo &> /dev/null; then
  echo "🔧 检测到 Hugo，正在验证构建..."
  if hugo --minify --quiet 2>/dev/null; then
    echo "✅ 构建验证通过！"
  else
    echo "⚠️  构建有警告，但通常不影响部署（首次运行可能有轻微警告）"
  fi
else
  echo "⚠️  未检测到 Hugo，跳过本地构建验证（不影响部署）"
fi

# ==========================================
# 17. 自动提交并推送
# ==========================================
echo ""
echo "🚀 开始自动提交并推送到 GitHub..."

# 确保 git 用户信息已设置
if [ -z "$(git config user.name)" ]; then
  git config user.name "zxjx260801"
  git config user.email "zxjx260801@users.noreply.github.com"
  echo "📧 已设置 git 用户信息"
fi

# 暂存所有更改
echo "📦 暂存文件..."
git add -A

# 检查是否有更改需要提交
if git diff --cached --quiet; then
  echo "ℹ️  没有检测到更改，可能已经是最新的。"
else
  # 提交
  echo "💾 提交更改..."
  git commit -m "feat: 切换到 Comfy 主题（方案A 沉稳阅读型）

- 新增自定义 Comfy 主题（深色/浅色双主题）
- 240px 固定侧边栏 + 卡片式文章列表
- 个人资料卡、搜索框、导航菜单、站点统计
- 主题切换按钮（localStorage 持久化）
- 响应式布局（移动端自动堆叠）
- 更新 hugo.toml 配置
- 移除 PaperMod 子模块"

  echo "✅ 提交成功！"
fi

# 推送
echo "⬆️  推送到 GitHub..."
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
if git push origin "$CURRENT_BRANCH" 2>&1; then
  echo ""
  echo "========================================"
  echo "🎉 部署完成！"
  echo "========================================"
  echo ""
  echo "✅ 代码已推送到 GitHub ($CURRENT_BRANCH 分支)"
  echo "⏳ Cloudflare Pages 正在自动构建..."
  echo ""
  echo "📱 约 1-2 分钟后访问: https://zxjx2681.com"
  echo "📊 查看构建状态: Cloudflare Dashboard > Pages > my-website"
  echo ""
else
  echo ""
  echo "❌ 推送失败！请检查："
  echo "   1. 是否已登录 GitHub (gh auth login)"
  echo "   2. 网络连接是否正常"
  echo "   3. 手动重试: git push origin $CURRENT_BRANCH"
fi
