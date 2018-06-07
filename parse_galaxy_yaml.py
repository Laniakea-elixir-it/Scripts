#!/usr/bin/env python
"""
derived from ansible ini_file module
https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/files/ini_file.py
"""

import sys, os
import argparse
import re

#import logging

logfile = '/tmp/readdb.log'

#______________________________________
def cli_options():
  parser = argparse.ArgumentParser(description='Read and modify galaxy.yaml file')
  parser.add_argument('-c', '--config-file', dest='config_file', help='galaxy yaml file')
  parser.add_argument('-s', '--section', dest='section', help='section')
  parser.add_argument('-o', '--option', dest='option', help='option')
  parser.add_argument('-v', '--value', dest='value', help='value')
  return parser.parse_args()

#______________________________________
def match_opt(option, line):
    option = re.escape(option)
    return re.match('( |\t)*%s( |\t)*(=|$)' % option, line) \
        or re.match('#( |\t)*%s( |\t)*(=|$)' % option, line) \
        or re.match(';( |\t)*%s( |\t)*(=|$)' % option, line)

#______________________________________
def do_yaml(config_file, section, option, value):

  fin = open(config_file, "r")
  try:
    yaml_lines = fin.readlines()
  finally:
    fin.close()

  within_section = not section
  section_start = 0

  for index, line in enumerate(yaml_lines):
    if line.startswith('%s:' % section): 
      print index
      within_section = True
      section_start = index
    #four_letter_words = regex.findall(line)
    #for word in four_letter_words:
    #  print line

  fin.close()

  return 0

#______________________________________
def parse_galaxy_yaml():

  options = cli_options()

  do_yaml(options.config_file, options.section, options.option, options.value)

  # find a section.
  # no indentation


  # find following section


  # search occurrence between line section +1 to next_section -1

  #indentazione
  #cerco la stringa con o senza # e con il : dopo uno spazio
  #gli do la sezione e comincia a leggere dalla ricorrenza fino alla successiva senza indentazione

  return 0

#______________________________________
if __name__ == '__main__':
  parse_galaxy_yaml()
