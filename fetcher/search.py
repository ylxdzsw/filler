# encoding: utf-8

import requests as req
from lxml import etree as xml

def get_pages(query):
    page1 = req.get("http://www.baidu.com/s", params={"wd":query})
    page2 = req.get("http://www.baidu.com/s", params={"wd":query, "pn":'10'})
    page3 = req.get("http://www.baidu.com/s", params={"wd":query, "pn":'20'})
    return page1, page2, page3

def retrive_content(page):
    abstracts = xml.HTML(page.text).xpath("//*[@class='c-abstract']")
    return map(lambda x: ''.join(x.itertext()), abstracts)

def search(keywords):
    try:
        pages = get_pages(' '.join(keywords))
        return (i for page in pages for i in retrive_content(page))
    except Exception as e:
        print(e)
