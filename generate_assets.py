#!/usr/bin/env python3
"""Generate image assets for TellMeMo landing page."""

from PIL import Image, ImageDraw, ImageFont
import os

# Create assets directory if it doesn't exist
os.makedirs('docs/assets', exist_ok=True)

# Colors matching the brand
PRIMARY_COLOR = (99, 102, 241)  # #6366F1
SECONDARY_COLOR = (139, 92, 246)  # #8B5CF6
WHITE = (255, 255, 255)

def create_gradient_background(width, height):
    """Create a gradient background from primary to secondary color."""
    image = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(image)

    for y in range(height):
        # Linear gradient from top-left to bottom-right
        ratio = y / height
        r = int(PRIMARY_COLOR[0] * (1 - ratio) + SECONDARY_COLOR[0] * ratio)
        g = int(PRIMARY_COLOR[1] * (1 - ratio) + SECONDARY_COLOR[1] * ratio)
        b = int(PRIMARY_COLOR[2] * (1 - ratio) + SECONDARY_COLOR[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    return image

def create_favicon(size):
    """Create a favicon with TellMeMo logo."""
    image = Image.new('RGB', (size, size), WHITE)
    draw = ImageDraw.Draw(image)

    # Create gradient circle
    for i in range(size):
        for j in range(size):
            # Check if pixel is inside circle
            dx = i - size/2
            dy = j - size/2
            distance = (dx*dx + dy*dy) ** 0.5

            if distance < size/2 - 2:
                ratio = distance / (size/2)
                r = int(PRIMARY_COLOR[0] * (1 - ratio) + SECONDARY_COLOR[0] * ratio)
                g = int(PRIMARY_COLOR[1] * (1 - ratio) + SECONDARY_COLOR[1] * ratio)
                b = int(PRIMARY_COLOR[2] * (1 - ratio) + SECONDARY_COLOR[2] * ratio)
                image.putpixel((i, j), (r, g, b))

    # Draw simplified "TM" icon
    padding = size // 6
    icon_size = size - 2 * padding

    # Draw two horizontal lines representing meeting notes
    line_height = icon_size // 8
    gap = icon_size // 5

    # Top line
    y1 = padding + icon_size // 3
    draw.rectangle(
        [padding, y1, size - padding, y1 + line_height],
        fill=WHITE
    )

    # Bottom line
    y2 = y1 + gap
    draw.rectangle(
        [padding, y2, size - padding, y2 + line_height],
        fill=WHITE
    )

    return image

def create_og_image():
    """Create Open Graph social sharing image (1200x630)."""
    width, height = 1200, 630
    image = create_gradient_background(width, height)
    draw = ImageDraw.Draw(image)

    # Try to use a nice font, fall back to default if not available
    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 40)
    except:
        try:
            title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 80)
            subtitle_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 40)
        except:
            title_font = ImageFont.load_default()
            subtitle_font = ImageFont.load_default()

    # Draw text
    title = "TellMeMo"
    subtitle = "AI-Powered Meeting Intelligence"

    # Calculate text position (centered)
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_height = title_bbox[3] - title_bbox[1]

    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_height = subtitle_bbox[3] - subtitle_bbox[1]

    # Draw title
    title_x = (width - title_width) // 2
    title_y = (height - title_height - subtitle_height - 40) // 2
    draw.text((title_x, title_y), title, fill=WHITE, font=title_font)

    # Draw subtitle
    subtitle_x = (width - subtitle_width) // 2
    subtitle_y = title_y + title_height + 40
    draw.text((subtitle_x, subtitle_y), subtitle, fill=WHITE, font=subtitle_font)

    # Draw decorative elements
    circle_radius = 60
    for i in range(3):
        x = 100 + i * 150
        y = height - 100
        draw.ellipse(
            [x - circle_radius, y - circle_radius, x + circle_radius, y + circle_radius],
            fill=(255, 255, 255, 50),
            outline=WHITE,
            width=3
        )

    return image

def create_twitter_card():
    """Create Twitter card image (1200x600)."""
    width, height = 1200, 600
    image = create_gradient_background(width, height)
    draw = ImageDraw.Draw(image)

    # Try to use a nice font
    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 75)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 38)
    except:
        try:
            title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 75)
            subtitle_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 38)
        except:
            title_font = ImageFont.load_default()
            subtitle_font = ImageFont.load_default()

    # Draw text
    title = "TellMeMo"
    subtitle = "Transform Meetings into Actionable Insights"

    # Calculate positions
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_height = title_bbox[3] - title_bbox[1]

    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_height = subtitle_bbox[3] - subtitle_bbox[1]

    # Draw centered text
    title_x = (width - title_width) // 2
    title_y = (height - title_height - subtitle_height - 30) // 2
    draw.text((title_x, title_y), title, fill=WHITE, font=title_font)

    subtitle_x = (width - subtitle_width) // 2
    subtitle_y = title_y + title_height + 30
    draw.text((subtitle_x, subtitle_y), subtitle, fill=WHITE, font=subtitle_font)

    return image

# Generate all assets
print("Generating favicon assets...")
favicon_16 = create_favicon(16)
favicon_16.save('docs/assets/favicon-16x16.png', 'PNG')
print("✓ Created favicon-16x16.png")

favicon_32 = create_favicon(32)
favicon_32.save('docs/assets/favicon-32x32.png', 'PNG')
print("✓ Created favicon-32x32.png")

favicon_180 = create_favicon(180)
favicon_180.save('docs/assets/apple-touch-icon.png', 'PNG')
print("✓ Created apple-touch-icon.png")

print("\nGenerating social media images...")
og_image = create_og_image()
og_image.save('docs/assets/og-image.png', 'PNG')
print("✓ Created og-image.png (1200x630)")

twitter_card = create_twitter_card()
twitter_card.save('docs/assets/twitter-card.png', 'PNG')
print("✓ Created twitter-card.png (1200x600)")

print("\n✅ All assets generated successfully in docs/assets/")
