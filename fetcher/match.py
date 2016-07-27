# encoding: utf-8

from search import search

def search_match(key, data, pattern):
    for (i, v) in enumerate(data):
        i += i >= key
        pattern = pattern.replace("$" + str(i), v)
    l,r = pattern.split("$%d" % key)
    results = search([l,r])
    values = {}

    if l == "":
        for result in results:
            v = result.split(r)
            if len(v) > 1:
                v = v[0]
                for i in range(max(0, len(v)-40), len(v)-1):
                    s = v[i:len(v)]
                    values[s] = values.get(s, 0) + 1
    elif r == "":
        for result in results:
            v = result.split(l)
            if len(v) > 1:
                v = v[1]
                for i in range(1, min(len(v), 40)):
                    s = v[0:i]
                    values[s] = values.get(s, 0) + 1
    else:
        for result in results:
            if l in result and r in result:
                v = result.split(l)[1].split(r)[0]
                values[v] = values.get(v, 0) + 1

    return max(values.items(), key=lambda x: x[1], default=("", 0))
