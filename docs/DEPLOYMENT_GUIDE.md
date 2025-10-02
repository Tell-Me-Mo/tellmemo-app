# 🚀 TellMeMo Landing Site - Quick Deployment Guide

This guide will help you deploy the TellMeMo landing site in under 10 minutes.

## 📋 Pre-Deployment Checklist

Before deploying, make sure you've configured:

- [ ] Google Analytics ID (in `index.html`)
- [ ] Formspree form ID (in `index.html`)
- [ ] Social media links (in `index.html` footer)
- [ ] Demo video URL (in `js/script.js`)
- [ ] Custom domain (if applicable)

## 🎯 Quick Start: GitHub Pages (5 minutes)

**Best for**: Quick deployment, free hosting, version control integration

### Steps:

1. **Push your code to GitHub**:
   ```bash
   git add .
   git commit -m "Add landing site"
   git push origin main
   ```

2. **Enable GitHub Pages**:
   - Go to: `https://github.com/YOUR_USERNAME/pm_master_v2/settings/pages`
   - Source: "Deploy from a branch"
   - Branch: `main`, Folder: `/docs`
   - Click "Save"

3. **Access your site**:
   - URL: `https://YOUR_USERNAME.github.io/pm_master_v2/`
   - Wait 2-3 minutes for deployment

### Custom Domain (Optional):

1. Create `docs/CNAME`:
   ```bash
   echo "tellmemo.app" > docs/CNAME
   git add docs/CNAME
   git commit -m "Add custom domain"
   git push
   ```

2. Configure DNS:
   - Add CNAME record: `www` → `YOUR_USERNAME.github.io`
   - Add A records for apex domain:
     ```
     185.199.108.153
     185.199.109.153
     185.199.110.153
     185.199.111.153
     ```

3. Enable HTTPS in GitHub Pages settings (automatic after DNS propagation)

## ⚡ Alternative: Netlify (Recommended for Production)

**Best for**: Professional deployment, instant SSL, global CDN, form handling

### One-Click Deploy:

1. Click the button below or go to [netlify.com](https://netlify.com):

   [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start)

2. **Configure build settings**:
   - Build command: *(leave empty)*
   - Publish directory: `docs`
   - Click "Deploy site"

3. **Your site is live!**
   - Netlify URL: `https://random-name-12345.netlify.app`

### Custom Domain on Netlify:

1. Go to: Site settings → Domain management
2. Click "Add custom domain"
3. Enter: `tellmemo.app`
4. Follow DNS instructions (usually just add CNAME)
5. SSL certificate is automatic ✅

## 🎨 Vercel Deployment

**Best for**: Next.js projects, but works great for static sites too

### Steps:

1. Go to [vercel.com](https://vercel.com/new)
2. Import your GitHub repository
3. Configure:
   - Root Directory: `docs`
   - Build Command: *(leave empty)*
   - Output Directory: `.`
4. Click "Deploy"
5. Access: `https://your-project.vercel.app`

### Custom Domain:
- Go to Project Settings → Domains
- Add your domain and follow DNS instructions

## 🔧 Configuration Steps

### 1. Google Analytics

1. Create account at [analytics.google.com](https://analytics.google.com)
2. Create property for your website
3. Get Measurement ID (format: `G-XXXXXXXXXX`)
4. Update `docs/index.html`:
   ```html
   <!-- Replace BOTH occurrences -->
   <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
   <script>
       gtag('config', 'G-XXXXXXXXXX');
   </script>
   ```

### 2. Contact Form (Formspree)

1. Sign up at [formspree.io](https://formspree.io) (free plan: 50 submissions/month)
2. Create new form
3. Copy Form ID (format: `xpzkwxxx`)
4. Update `docs/index.html`:
   ```html
   <form action="https://formspree.io/f/xpzkwxxx" method="POST">
   ```

**Alternative (Netlify Forms)**:
If using Netlify, simply add `netlify` attribute:
```html
<form name="contact" method="POST" netlify>
```

### 3. Social Media Links

Update in `docs/index.html` footer:
```html
<!-- Twitter -->
<a href="https://twitter.com/tellmemo" aria-label="Twitter">

<!-- LinkedIn -->
<a href="https://linkedin.com/company/tellmemo" aria-label="LinkedIn">

<!-- GitHub -->
<a href="https://github.com/yourusername/pm_master_v2" aria-label="GitHub">
```

### 4. Demo Video

Update `docs/js/script.js` line ~311:
```javascript
// Replace with your YouTube, Vimeo, or Loom video
window.open('https://www.youtube.com/watch?v=YOUR_VIDEO_ID', '_blank');
```

## 📊 Performance Optimization

### Lighthouse Score Checklist:

- [x] Optimized images (assets are already PNG compressed)
- [x] Minified CSS & JS
- [x] Lazy loading images
- [x] Proper meta tags
- [x] Mobile responsive
- [x] Accessibility features

### Further Optimization:

1. **Compress images further**:
   ```bash
   # Install ImageMagick
   brew install imagemagick  # macOS
   
   # Compress PNG files
   for file in docs/assets/*.png; do
       convert "$file" -quality 85 "$file"
   done
   ```

2. **Enable Caching** (if using custom server):
   ```nginx
   # In nginx config
   location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
       expires 1y;
       add_header Cache-Control "public, immutable";
   }
   ```

3. **Add CDN** (Cloudflare):
   - Sign up at [cloudflare.com](https://cloudflare.com)
   - Add your site
   - Update nameservers
   - Enable "Auto Minify" for HTML, CSS, JS

## 🧪 Testing Before Launch

1. **Test locally**:
   ```bash
   # Option 1: Python
   cd docs
   python3 -m http.server 8000
   # Visit: http://localhost:8000

   # Option 2: Node.js
   npx serve docs
   ```

2. **Check responsiveness**:
   - Chrome DevTools (F12) → Toggle device toolbar
   - Test mobile, tablet, desktop views

3. **Test forms**:
   - Fill out contact form
   - Check email receipt (if using Formspree)

4. **Validate HTML/CSS**:
   - HTML: [validator.w3.org](https://validator.w3.org)
   - CSS: [jigsaw.w3.org/css-validator](https://jigsaw.w3.org/css-validator/)

5. **Run Lighthouse**:
   - Chrome DevTools → Lighthouse tab
   - Run audit for Performance, Accessibility, Best Practices, SEO
   - Target: All scores 90+

## 🐛 Troubleshooting

### Issue: GitHub Pages shows 404

**Solution**: 
- Check that `/docs` folder is published, not root
- Ensure `index.html` exists in `docs/` folder
- Wait 2-3 minutes after enabling Pages

### Issue: Images not loading

**Solution**:
- Check image paths (should be `assets/image.png`, not `/assets/image.png`)
- Verify images exist in `docs/assets/` folder
- Check browser console for 404 errors

### Issue: Contact form not working

**Solution**:
- Verify Formspree form ID is correct
- Check form `action` attribute
- Test with valid email address
- Check Formspree dashboard for submissions

### Issue: CSS/JS not loading

**Solution**:
- Check paths are relative: `css/style.css` not `/css/style.css`
- Clear browser cache (Cmd+Shift+R / Ctrl+Shift+R)
- Check browser console for errors

## 📈 Post-Launch

### Monitor Analytics:
1. Check Google Analytics dashboard daily for first week
2. Monitor:
   - Page views
   - Bounce rate
   - Average session duration
   - Traffic sources
   - Conversion rate (form submissions)

### SEO:
1. Submit sitemap to Google Search Console:
   - Add property: `https://tellmemo.app`
   - Submit sitemap: `https://tellmemo.app/sitemap.xml`

2. Submit to Bing Webmaster Tools

3. Check indexing:
   - Google: `site:tellmemo.app`
   - Should see your pages within 1-2 weeks

### Performance Monitoring:
1. Set up [Uptime Robot](https://uptimerobot.com) (free)
2. Monitor site availability
3. Get alerts if site goes down

## 🎉 You're Live!

Your TellMeMo landing site is now live and ready to capture leads!

### Next Steps:
1. Share your site: [tellmemo.app](https://tellmemo.app)
2. Add link to social media bios
3. Create launch post on LinkedIn/Twitter
4. Monitor form submissions
5. Iterate based on user feedback

---

Need help? Check the [main README](../README.md) or create an issue.
