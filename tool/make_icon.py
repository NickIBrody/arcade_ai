import math
from PIL import Image, ImageDraw, ImageFilter

S = 1024
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))


def rounded(size, radius, fill):
    m = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=fill)
    return m


# --- background: near-black rounded square with a violet corner glow ---
bg = rounded(S, int(S * 0.235), (8, 6, 12, 255))

glow_bg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow_bg)
gd.ellipse([-S * 0.2, -S * 0.3, S * 0.7, S * 0.5], fill=(109, 40, 217, 150))
gd.ellipse([S * 0.55, S * 0.6, S * 1.25, S * 1.3], fill=(139, 92, 246, 90))
glow_bg = glow_bg.filter(ImageFilter.GaussianBlur(120))

mask = rounded(S, int(S * 0.235), (255, 255, 255, 255)).split()[3]
bg.paste(glow_bg, (0, 0), glow_bg)
bg.putalpha(mask)
img.alpha_composite(bg)


def sparkle(cx, cy, R, inner=0.16):
    pts = []
    for i in range(8):
        ang = math.radians(i * 45)
        rad = R if i % 2 == 0 else R * inner
        pts.append((cx + rad * math.cos(ang), cy - rad * math.sin(ang)))
    return pts


def gradient(size, c1, c2):
    g = Image.new("RGBA", (size, size))
    px = g.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            px[x, y] = (
                int(c1[0] + (c2[0] - c1[0]) * t),
                int(c1[1] + (c2[1] - c1[1]) * t),
                int(c1[2] + (c2[2] - c1[2]) * t),
                255,
            )
    return g


# --- main sparkle ---
star_mask = Image.new("L", (S, S), 0)
sd = ImageDraw.Draw(star_mask)
sd.polygon(sparkle(S * 0.5, S * 0.5, S * 0.30, 0.17), fill=255)
sd.polygon(sparkle(S * 0.72, S * 0.30, S * 0.085, 0.18), fill=255)

grad = gradient(S, (196, 167, 250), (109, 40, 217))

# soft glow under the sparkle
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
glow.paste((139, 92, 246, 255), (0, 0), star_mask)
glow = glow.filter(ImageFilter.GaussianBlur(46))
img.alpha_composite(Image.composite(glow, Image.new("RGBA", (S, S), (0, 0, 0, 0)), mask))

star = Image.new("RGBA", (S, S), (0, 0, 0, 0))
star.paste(grad, (0, 0), star_mask)
star.putalpha(Image.composite(star_mask, Image.new("L", (S, S), 0), mask))
img.alpha_composite(star)

img.save("assets/icons/icon.png")

# foreground (adaptive) — transparent bg, just the glowing sparkle, a bit smaller
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
fg.alpha_composite(glow)
fg.alpha_composite(star)
fg.save("assets/icons/icon_foreground.png")
print("icons written")
