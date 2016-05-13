import tracemalloc
tracemalloc.start()
n = 10000
a = tuple(0 for _ in range(n))
b = list(0 for _ in range(n))

snapshot = tracemalloc.take_snapshot()
print( snapshot.statistics('lineno'))

