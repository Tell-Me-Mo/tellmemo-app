# TellMeMo Website - GitHub Pages

This is the marketing website for TellMeMo (formerly PM Master V2), an AI-powered meeting intelligence and project management platform.

## 🚀 Quick Start

### Deployment to GitHub Pages

1. Push this code to your GitHub repository
2. Go to Settings → Pages in your GitHub repository
3. Under "Source", select "Deploy from a branch"
4. Select `main` branch and `/docs` folder
5. Click Save
6. Your site will be available at: `https://[your-username].github.io/pm_master_v2/`

### Important Configuration

Before deploying, update the following:

1. **Update URLs in all files:**
   - Replace `yourusername` with your GitHub username in:
     - `index.html` (meta tags)
     - `blog.html` (meta tags)
     - `sitemap.xml` (all URLs)
     - `robots.txt` (sitemap URL)

2. **Update base URL if repository name is different:**
   - If your repository is not named `pm_master_v2`, update all relative paths

## 📁 Structure

```
docs/
├── index.html          # Main landing page
├── blog.html           # Blog listing page
├── 404.html           # Custom 404 error page
├── manifest.json      # PWA manifest
├── robots.txt         # SEO robots file
├── sitemap.xml        # SEO sitemap
├── css/
│   ├── style.css      # Main stylesheet
│   └── blog.css       # Blog-specific styles
├── js/
│   ├── script.js      # Main JavaScript
│   └── blog.js        # Blog functionality
├── blog/
│   └── *.html        # Individual blog posts
└── assets/
    └── favicon.svg    # Site favicon
```

## 🎨 Design Features

- **Material Design 3** inspired UI
- **Responsive Design** for all screen sizes
- **Dark/Light mode** ready (CSS variables)
- **Smooth animations** and transitions
- **SEO optimized** with meta tags and sitemap
- **PWA ready** with manifest.json

## 🔧 Customization

### Colors
Edit CSS variables in `css/style.css`:
```css
:root {
    --primary-color: #6366F1;
    --secondary-color: #8B5CF6;
    /* ... other colors */
}
```

### Content
- Edit text directly in HTML files
- Blog posts are in the `blog/` directory
- Add new blog posts by creating new HTML files

### Analytics
Add your Google Analytics or other tracking codes in the `<head>` section of HTML files.

## 📝 Blog Management

To add a new blog post:

1. Create a new HTML file in `blog/` directory
2. Use `blog/rag-revolution.html` as a template
3. Add the post to `blog.html` listing
4. Update `sitemap.xml` with the new URL

## 🔍 SEO Checklist

- ✅ Meta tags on all pages
- ✅ Open Graph tags for social sharing
- ✅ Sitemap.xml for search engines
- ✅ Robots.txt for crawler guidance
- ✅ Semantic HTML structure
- ✅ Schema.org structured data
- ✅ Mobile-responsive design
- ✅ Fast loading times

## 📱 Progressive Web App

The site includes PWA capabilities:
- Manifest.json for app-like experience
- Service worker ready (add sw.js if needed)
- Responsive design for all devices

## 🛠 Development

To work locally:
1. Clone the repository
2. Open `docs/index.html` in a browser
3. For hot reload, use a local server:
   ```bash
   python -m http.server 8000
   # or
   npx serve docs
   ```

## 📄 License

This website is part of the TellMeMo project.

## 🤝 Support

For issues or questions about the website, please open an issue in the main repository.