# encoding: utf-8

from search import search

def find_patterns(data):
    results = search(data)
    for result in results:
        for i in range(0, len(result)):
            for j in range(i+1, min(i+40, len(result))):
                yield extract_patterns(result[i:j], data)

def extract_patterns(text, data):
    nkeyword = 0
    for key in data:
        if key in text:
            nkeyword += 1
            if nkeyword >= 2:
                for (i, key) in enumerate(data):
                    text = text.replace(key, "$%d" % i)
                return text
    return ""

def top_patterns(data, n=5):
    patterns = {}
    for i in data:
        for p in find_patterns(i):
            patterns[p] = patterns.get(p, 0) + 1
    freq_patterns = filter(lambda x: x[1]>1, patterns.items())
    score = lambda x: x[1] * (20 + len(x[0])) # the longer, the better
    return sorted(freq_patterns, reverse=True, key=score)[:n]
