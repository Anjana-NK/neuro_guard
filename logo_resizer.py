import os
from PIL import Image

def resize_icon():
    source_img_path = r"C:\Users\User\.gemini\antigravity-ide\brain\0d6991e8-6af4-4f56-8887-4bda1de679ed\media__1781802566117.png"
    if not os.path.exists(source_img_path):
        print(f"Error: Source image not found at {source_img_path}")
        return

    # Load source image
    img = Image.open(source_img_path)
    
    # Target folders and sizes
    android_res_path = r"d:\USER FILES\Documents\neuro_guard\frontend\android\app\src\main\res"
    sizes = {
        "mipmap-mdpi": (48, 48),
        "mipmap-hdpi": (72, 72),
        "mipmap-xhdpi": (96, 96),
        "mipmap-xxhdpi": (144, 144),
        "mipmap-xxxhdpi": (192, 192)
    }

    # Generate Android mipmap icons
    for folder, size in sizes.items():
        dest_dir = os.path.join(android_res_path, folder)
        if os.path.exists(dest_dir):
            dest_file = os.path.join(dest_dir, "ic_launcher.png")
            resized = img.resize(size, Image.Resampling.LANCZOS)
            resized.save(dest_file, "PNG")
            print(f"Saved: {dest_file} ({size[0]}x{size[1]})")
        else:
            print(f"Warning: Directory {dest_dir} does not exist!")

    # Generate frontend assets
    assets_dir = r"d:\USER FILES\Documents\neuro_guard\frontend\assets\images"
    os.makedirs(assets_dir, exist_ok=True)
    
    # Overwrite Welcome.png with a larger size of the brand icon
    welcome_file = os.path.join(assets_dir, "Welcome.png")
    welcome_img = img.resize((512, 512), Image.Resampling.LANCZOS)
    welcome_img.save(welcome_file, "PNG")
    print(f"Saved welcome brand image: {welcome_file}")

    # Save app_logo.png
    logo_file = os.path.join(assets_dir, "app_logo.png")
    logo_img = img.resize((256, 256), Image.Resampling.LANCZOS)
    logo_img.save(logo_file, "PNG")
    print(f"Saved app logo: {logo_file}")

if __name__ == "__main__":
    resize_icon()
