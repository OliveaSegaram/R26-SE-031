from PIL import Image, ImageDraw
import os

images_dir = "app/frontend/assets/images"
chars = ["solo_blue.png"]

def remove_background(img_path):
    img = Image.open(img_path).convert("RGBA")
    width, height = img.size
    
    # Simple transparent replacement for near-white pixels near edges
    # We use flood fill from the 4 corners to fill with a special color, then make that color transparent.
    
    # Create a temporary color that is very unlikely to be in the image
    magic_color = (255, 0, 255, 255) # Magenta
    
    # Instead of full flood fill logic, ImageDraw.floodfill works on the image directly
    # We will flood fill from all 4 corners with magenta if the pixel is near white
    
    # To use ImageDraw.floodfill, it expects an exact match or threshold?
    # Pillow's floodfill doesn't have a threshold until very recent versions.
    # Let's do a fast BFS using a queue
    
    data = img.load()
    
    from collections import deque
    visited = set()
    queue = deque()
    
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))
        
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        
        r, g, b, a = data[x, y]
        # If near white (bg is usually >230 RGB)
        if r > 230 and g > 230 and b > 230 and a > 0:
            data[x, y] = (0, 0, 0, 0)
            if x > 0: queue.append((x - 1, y))
            if x < width - 1: queue.append((x + 1, y))
            if y > 0: queue.append((x, y - 1))
            if y < height - 1: queue.append((x, y + 1))

    # Removed special handling for solo_blue.png to preserve its feet

    img.save(img_path)
    print(f"Processed {img_path}")

for c in chars:
    path = os.path.join(images_dir, c)
    if os.path.exists(path):
        remove_background(path)
