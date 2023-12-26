# -*- coding: utf-8 -*-
# XML parser 

import re
import os
from xml.etree import ElementTree

class Error(Exception):
    """ An exeception class for XML_Parser. """
    pass

def node_to_dictionary(node):
    """ Convert a element tree to a dictionary. """
    def to_dictionary(node):
        dic = {}
        for childNode in node:
            childDic = to_dictionary(childNode)
            if childNode.tag in dic:
                dic[childNode.tag].append(childDic)
            else:
                dic[childNode.tag] = [childDic]
        for key, value in node.attrib.items():
            keyName = "@" + key
            dic[keyName] = value
        return dic
    return {node.tag: to_dictionary(node)}

def dictionary_to_node(dic):
    """ Convert a dictionary to a element tree. """
        
    def to_element(tag, dic):
        """ Convert a dictionary to a element node. """
        node = ElementTree.Element(tag)
        #node.tail = "\n"
        for child in sorted(dic.keys()):
            if child[0] == "@":
                node.attrib[child[1:]] = dic[child]
            else:
                if type(dic[child]) == list:
                    for i in dic[child]:
                        node.append(to_element(child, i))
                else:
                    node.append(to_element(child, dic[child]))
        return node
        
    if len(dic) != 1:
        raise Error("Dictionary data has no root node or multiple root nodes.")

    rootTag = list(dic.keys())[0]
    return to_element(rootTag, dic[rootTag])

def load_file(fileName):
    """ Load a XML file """
    tree = ElementTree.parse(fileName)
    return node_to_dictionary(tree.getroot())
    
def save_file(fileName, dic):
    """ Save a XML file """

    def indent(elem, level=0):
        i = "\n" + level*"  "
        if len(elem):
            if not elem.text or not elem.text.strip():
                elem.text = i + "  "
            if not elem.tail or not elem.tail.strip():
                elem.tail = i
            for elem in elem:
                indent(elem, level+1)
            if not elem.tail or not elem.tail.strip():
                elem.tail = i
        else:
            if level and (not elem.tail or not elem.tail.strip()):
                elem.tail = i

    elementRoot = dictionary_to_node(dic)
    indent(elementRoot)
    tree = ElementTree.ElementTree(elementRoot)
    tree.write(
        fileName, 
        encoding="utf-8", 
        xml_declaration='<?xml version="1.0" encoding="utf-8" ?>\n',
        method="xml"
    )

def to_string(dic):
    """ To XML string. """
    elementRoot = dictionary_to_node(dic)
    return ElementTree.tostring(elementRoot)

        