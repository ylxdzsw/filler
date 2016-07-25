# encoding: utf-8

import requests as req
from lxml import etree as xml

def get_page(query):
    return req.get("http://www.baidu.com/s", params={"wd":query})

def retrive_content(page):
    abstracts = xml.HTML(page.text).xpath("//*[@class='c-abstract']")
    return map(lambda x: ''.join(x.itertext()), abstracts)

def search(keywords):
    try:
        page = get_page(' '.join(keywords))
        return retrive_content(page)
    except Exception as e:
        print(e)
