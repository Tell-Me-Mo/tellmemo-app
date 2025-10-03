# TellMeMo Documentation Website

This directory contains the static documentation and marketing website for TellMeMo, an AI-powered meeting intelligence platform.

## 📁 Structure

```
docs/
├── index.html              # Main landing page
├── documentation.html      # Full documentation
├── blog.html              # Blog listing page
├── privacy.html           # Privacy policy
├── terms.html             # Terms of service
├── 404.html               # Custom 404 error page
├── manifest.json          # PWA manifest
├── robots.txt             # SEO robots file
├── sitemap.xml            # SEO sitemap
├── DEPLOYMENT_GUIDE.md    # Website deployment instructions
├── css/
│   ├── style.css          # Main stylesheet
│   └── blog.css           # Blog-specific styles
├── js/
│   ├── script.js          # Main JavaScript
│   └── blog.js            # Blog functionality
├── blog/
│   └── *.html             # Individual blog posts
└── assets/
    └── *.svg/png          # Images, favicons, etc.
```

## 🎨 Features

- **Responsive Design** - Works on all devices (desktop, tablet, mobile)
- **SEO Optimized** - Meta tags, sitemap, structured data
- **Material Design 3** - Modern, clean UI design
- **PWA Ready** - Progressive Web App capabilities
- **Fast Loading** - Optimized assets and code

## 🔧 Local Development

To work on the documentation locally:

```bash
# Option 1: Python HTTP server
cd docs
python -m http.server 8000

# Option 2: Node.js serve
npx serve docs

# Option 3: Any local web server
# Then open http://localhost:8000 in your browser
```

## 📝 Editing Documentation

### Main Documentation
Edit `documentation.html` to update:
- Installation instructions
- Configuration options
- User guides
- Troubleshooting
- API reference

### Landing Page
Edit `index.html` to update:
- Hero section
- Features
- Use cases
- Testimonials
- FAQ

### Blog Posts
To add a new blog post:
1. Create a new HTML file in `blog/` directory
2. Use `blog/rag-revolution.html` as a template
3. Add the post to `blog.html` listing
4. Update `sitemap.xml` with the new URL

## 🎨 Styling

All styles are in `css/style.css`. The design uses CSS variables for easy customization:

```css
:root {
    --primary-color: #6366F1;
    --secondary-color: #8B5CF6;
    --bg-primary: #FFFFFF;
    --text-primary: #1A202C;
    /* ... more variables */
}
```

## 🔍 SEO

The site includes:
- ✅ Meta tags (title, description, keywords)
- ✅ Open Graph tags for social sharing
- ✅ Twitter Card tags
- ✅ Sitemap.xml for search engines
- ✅ Robots.txt for crawler guidance
- ✅ Schema.org structured data
- ✅ Semantic HTML5 markup

## 📱 Progressive Web App

The site can be installed as a PWA:
- `manifest.json` - App metadata and icons
- Responsive design for mobile devices
- Add `sw.js` (service worker) for offline support if needed

## 🚀 Deployment

This documentation website is deployed via GitHub Pages. See `DEPLOYMENT_GUIDE.md` for detailed deployment instructions.

## 📄 License

This documentation is part of the TellMeMo project.

## 🤝 Contributing

To contribute to the documentation:
1. Make your changes locally
2. Test thoroughly across different browsers
3. Submit a pull request with clear description of changes

For questions or issues about the documentation website, please open an issue in the main repository.
