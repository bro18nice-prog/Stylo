from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
im = Image.open(ROOT / 'assets/branding/stylo-gothic-master.png').convert('RGBA')
background = Image.new('RGBA', im.size, '#100A0D')
background.alpha_composite(im)
im = background.convert('RGB')
im.resize((1024, 1024), Image.Resampling.LANCZOS).save(ROOT / 'assets/images/stylo_icon.png')
for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    im.resize((size,size),Image.Resampling.LANCZOS).save(ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
print('StylO gothic Android icons generated.')
