from PIL import Image, ImageDraw, ImageFont
import textwrap

from numpy import result_type

# Example image canvas
img = Image.new("RGB", (1000, 300), "black")
draw = ImageDraw.Draw(img)

# Load a font (choose your size)
font = ImageFont.truetype("arial.ttf", 30)

# Result text
result_text = result_type.replace(" ", "\u00A0")

# ✅ Wrap text so spaces are preserved and long sentences break into lines
wrapped_text = textwrap.fill(result_text, width=60)

# Draw the wrapped text on canvas
draw.multiline_text((50, 120), wrapped_text, font=font, fill="white" , spacing=15 )

# Show or save
img.show()
# img.save("output.png")
