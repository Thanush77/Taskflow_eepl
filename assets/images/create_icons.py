#!/usr/bin/env python3
"""
Script to generate TaskFlow app icons for different platforms
"""
import os
from PIL import Image, ImageDraw
import math

def create_gradient_circle(size, center, radius, color1, color2):
    """Create a gradient filled circle"""
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create gradient effect by drawing multiple circles
    steps = 50
    for i in range(steps):
        alpha = i / steps
        # Interpolate between colors
        r = int(color1[0] * (1 - alpha) + color2[0] * alpha)
        g = int(color1[1] * (1 - alpha) + color2[1] * alpha)
        b = int(color1[2] * (1 - alpha) + color2[2] * alpha)
        
        current_radius = radius * (1 - alpha * 0.3)
        color = (r, g, b, 255)
        
        draw.ellipse([
            center[0] - current_radius,
            center[1] - current_radius,
            center[0] + current_radius,
            center[1] + current_radius
        ], fill=color)
    
    return img

def create_taskflow_icon(size):
    """Create TaskFlow icon at given size"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = (size // 2, size // 2)
    main_radius = size * 0.47
    
    # Colors
    primary_start = (99, 102, 241)  # #6366f1
    primary_end = (139, 92, 246)   # #8b5cf6
    white = (255, 255, 255, 255)
    
    # Create main gradient background
    gradient_bg = create_gradient_circle((size, size), center, main_radius, primary_start, primary_end)
    img.paste(gradient_bg, (0, 0), gradient_bg)
    
    # Scale factors for different elements
    scale = size / 512
    
    # Main checkmark circle
    check_center = (int(180 * scale), int(200 * scale))
    check_radius = int(45 * scale)
    
    # Draw checkmark background circle
    draw.ellipse([
        check_center[0] - check_radius,
        check_center[1] - check_radius,
        check_center[0] + check_radius,
        check_center[1] + check_radius
    ], fill=white, outline=white, width=int(4 * scale))
    
    # Draw checkmark
    check_width = int(6 * scale)
    check_points = [
        (int(160 * scale), int(200 * scale)),
        (int(175 * scale), int(215 * scale)),
        (int(200 * scale), int(185 * scale))
    ]
    
    # Draw checkmark lines
    draw.line([check_points[0], check_points[1]], fill=primary_start, width=check_width)
    draw.line([check_points[1], check_points[2]], fill=primary_start, width=check_width)
    
    # Flow lines
    line_y1 = int(200 * scale)
    line_y2 = int(240 * scale)
    line_y3 = int(280 * scale)
    
    draw.line([(int(240 * scale), line_y1), (int(350 * scale), line_y1)], 
              fill=white, width=int(8 * scale))
    draw.line([(int(240 * scale), line_y2), (int(380 * scale), line_y2)], 
              fill=white, width=int(6 * scale))
    draw.line([(int(240 * scale), line_y3), (int(320 * scale), line_y3)], 
              fill=white, width=int(4 * scale))
    
    # Secondary checkmark circles
    circles = [
        (int(360 * scale), int(200 * scale), int(20 * scale)),
        (int(390 * scale), int(240 * scale), int(16 * scale)),
        (int(330 * scale), int(280 * scale), int(12 * scale))
    ]
    
    for cx, cy, radius in circles:
        draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], 
                    fill=white)
        
        # Small checkmarks
        if radius >= int(12 * scale):
            check_scale = radius / (20 * scale)
            small_check_width = max(1, int(3 * scale * check_scale))
            offset = int(7 * scale * check_scale)
            
            draw.line([(cx - offset, cy), (cx - offset//2, cy + offset//2)], 
                     fill=primary_start, width=small_check_width)
            draw.line([(cx - offset//2, cy + offset//2), (cx + offset, cy - offset)], 
                     fill=primary_start, width=small_check_width)
    
    return img

# Create icons for different platforms
sizes = {
    # Android
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    
    # iOS
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
    
    # Web
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
    'web/favicon.png': 32,
    
    # Assets
    'assets/images/taskflow_logo_512.png': 512,
    'assets/images/taskflow_logo_256.png': 256,
    'assets/images/taskflow_logo_128.png': 128,
    'assets/images/taskflow_logo_64.png': 64,
}

# Generate all icons
base_dir = '/Users/thanush/Desktop/codes/newgen/taskflow_flutter/taskflow_flutter'

for path, size in sizes.items():
    full_path = os.path.join(base_dir, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    
    icon = create_taskflow_icon(size)
    icon.save(full_path, 'PNG')
    print(f"Created: {path} ({size}x{size})")

print("\nAll TaskFlow icons generated successfully!")