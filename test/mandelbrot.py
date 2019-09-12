def mandel_iter(cx, cy, xscl, yscl):
    x0 = 0.45 - cx / xscl / 0.5
    y0 = 1 - cy / yscl / 0.5
    x = 0
    y = 0
    max_count = 1000
    count = 0
    while max_count > count and 16 > x * x + y * y:
        xtemp = x0 + x * x - y * y
        y = y0 + 2 * x * y
        x = xtemp
        count += 1
    if max_count - 1 >= count:
        print("#", end='')
    else:
        print(" ", end='')

def mandel(size):
    iy = size * 2
    ix = size
    for x in range(ix):
        for y in range(iy):
            mandel_iter(x, y, ix, iy)
        print()

mandel(50)