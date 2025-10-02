# TellMeMo (PM Master V2)

**TellMeMo** is an AI-powered Meeting Intelligence and Project Management Platform that uses RAG (Retrieval Augmented Generation) to help teams extract insights from meeting transcripts and emails, generate summaries, and track project progress.

## 📋 Project Overview

- **Frontend**: Flutter (cross-platform: Web, iOS, Android, macOS, Windows)
- **Backend**: FastAPI (Python)
- **Databases**: PostgreSQL (metadata), Qdrant (vector search)
- **AI/ML**: Claude 3.5 Haiku (LLM), SentenceTransformers (embeddings)
- **Monitoring**: Langfuse (LLM observability)

## 🌐 Landing Website

The project includes a production-ready landing website located in the `docs/` folder.

### Landing Site Structure

```
docs/
├── index.html          # Main landing page
├── blog.html           # Blog index
├── blog/
│   └── rag-revolution.html
├── css/
│   ├── style.css       # Main styles
│   └── blog.css        # Blog styles
├── js/
│   ├── script.js       # Main JavaScript
│   └── blog.js         # Blog JavaScript
├── assets/
│   ├── favicon-16x16.png
│   ├── favicon-32x32.png
│   ├── apple-touch-icon.png
│   ├── og-image.png    # Social sharing (1200x630)
│   └── twitter-card.png # Twitter card (1200x600)
├── sitemap.xml         # SEO sitemap
└── robots.txt          # Search engine rules
```

### Features

✅ **Modern Design**: Material Design 3 inspired, gradient backgrounds, smooth animations
✅ **Fully Responsive**: Mobile, tablet, and desktop optimized
✅ **Performance Optimized**: Lazy loading, optimized animations, fast load times
✅ **SEO Ready**: Meta tags, OpenGraph, Twitter Cards, sitemap, robots.txt
✅ **Contact Form**: Integrated modal with Formspree support
✅ **CTA Tracking**: Google Analytics ready (placeholder)
✅ **Accessibility**: ARIA labels, keyboard navigation, semantic HTML

## 🚀 Deploying the Landing Site

### Option 1: GitHub Pages (Free)

1. **Enable GitHub Pages**:
   - Go to your repository settings
   - Navigate to "Pages" section
   - Set source to "Deploy from a branch"
   - Select branch: `main` (or `master`)
   - Select folder: `/docs`
   - Click "Save"

2. **Configure Custom Domain** (Optional):
   - Create a `CNAME` file in `docs/`:
     ```bash
     echo "tellmemo.app" > docs/CNAME
     ```
   - Update your DNS settings:
     - Add a CNAME record pointing to `yourusername.github.io`
   - Update URLs in `docs/index.html` to match your domain

3. **Access your site**:
   - GitHub Pages URL: `https://yourusername.github.io/pm_master_v2/`
   - Custom domain: `https://tellmemo.app/`

### Option 2: Netlify (Recommended)

1. **Deploy to Netlify**:
   - Go to [netlify.com](https://netlify.com)
   - Click "Add new site" → "Import an existing project"
   - Connect your GitHub repository
   - Set build settings:
     - Base directory: `docs`
     - Build command: *(leave empty)*
     - Publish directory: `.` (current directory)
   - Click "Deploy site"

2. **Configure Custom Domain**:
   - Go to Site settings → Domain management
   - Click "Add custom domain"
   - Follow DNS configuration instructions

3. **Enable HTTPS**: Automatic with Netlify

### Option 3: Vercel

1. **Deploy to Vercel**:
   - Go to [vercel.com](https://vercel.com)
   - Click "New Project"
   - Import your repository
   - Override settings:
     - Root Directory: `docs`
     - Build Command: *(leave empty)*
     - Output Directory: `.`
   - Click "Deploy"

2. **Custom Domain**: Similar to Netlify

### Option 4: Custom Server (VPS/Cloud)

1. **Upload files**:
   ```bash
   # Using SCP
   scp -r docs/* user@your-server.com:/var/www/tellmemo/

   # Or use rsync
   rsync -avz docs/ user@your-server.com:/var/www/tellmemo/
   ```

2. **Configure Nginx**:
   ```nginx
   server {
       listen 80;
       server_name tellmemo.app www.tellmemo.app;
       root /var/www/tellmemo;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

3. **Enable HTTPS** with Let's Encrypt:
   ```bash
   sudo certbot --nginx -d tellmemo.app -d www.tellmemo.app
   ```

## ⚙️ Configuration

### 1. Google Analytics

Replace `GA_MEASUREMENT_ID` in `docs/index.html` with your Google Analytics ID:

```javascript
gtag('config', 'YOUR_GA_MEASUREMENT_ID');
```

### 2. Contact Form (Formspree)

1. Sign up at [formspree.io](https://formspree.io)
2. Create a new form
3. Replace `YOUR_FORM_ID` in `docs/index.html`:
   ```html
   <form action="https://formspree.io/f/YOUR_FORM_ID" method="POST">
   ```

### 3. Social Media Links

Update social media links in footer of `docs/index.html`:
```html
<a href="https://twitter.com/tellmemo" aria-label="Twitter">
<a href="https://linkedin.com/company/tellmemo" aria-label="LinkedIn">
<a href="https://github.com/yourusername/pm_master_v2" aria-label="GitHub">
```

### 4. Demo Video

Update the demo video URL in `docs/js/script.js`:
```javascript
window.open('YOUR_DEMO_VIDEO_URL', '_blank');
```

## 🛠️ Development Setup

### Prerequisites

- **Flutter SDK** ≥3.9.0
- **Dart SDK** ≥3.9.0
- **Python** 3.9+
- **Docker** & Docker Compose (for PostgreSQL, Qdrant, Langfuse)
- **Node.js** (for Langfuse frontend)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/pm_master_v2.git
   cd pm_master_v2
   ```

2. **Set up environment variables**
   ```bash
   # Root environment
   cp .env.example .env

   # Backend environment
   cp backend/.env.example backend/.env

   # Edit both .env files with your API keys and configuration
   ```

3. **Start Docker services**
   ```bash
   docker-compose up -d
   ```

4. **Set up Python backend**
   ```bash
   cd backend
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt

   # Initialize database
   python db/init_db.py

   # Start backend server
   uvicorn main:app --reload --port 8000
   ```

5. **Run Flutter app** (in separate terminal)
   ```bash
   flutter pub get
   flutter run -d chrome  # Web (default: http://localhost:8100)
   flutter run -d macos   # macOS desktop
   ```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Run tests
flutter test

# Python tests
cd backend && pytest

# Python linting
cd backend && flake8 . && black --check .
```

## 📚 Documentation

- **High-Level Design**: See [HLD_MVP.md](HLD_MVP.md)
- **User Journey**: See [USER_JOURNEY_MVP.md](USER_JOURNEY_MVP.md)
- **Claude Instructions**: See [CLAUDE.md](CLAUDE.md)

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to get started.

Quick start:
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔒 Security

If you discover a security vulnerability, please see [SECURITY.md](SECURITY.md) for reporting instructions.

## 📧 Contact

- Website: [https://tellmemo.app](https://tellmemo.app)
- Email: contact@tellmemo.app
- Twitter: [@tellmemo](https://twitter.com/tellmemo)

---

Built with ❤️ using Flutter and AI
