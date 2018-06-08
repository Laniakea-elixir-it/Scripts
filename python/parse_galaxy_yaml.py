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
def do_yaml(config_file, section, option, value, state):

  fin = open(config_file, "r")
  try:
    yaml_lines = fin.readlines()
  finally:
    fin.close()

  # If config_file is unmodified, do not write it.
  changed = False

  # append a fake section line to simplify the logic
  yaml_lines.append('[')

  within_section = not section
  section_start = 0

  for index, line in enumerate(yaml_lines):
    if line.startswith('%s:' % section): 
      within_section = True
      section_start = index
      print 'ciao'
    elif line.startswith('[^\s]+'):
      print 'ciao'
    # qui lui dice, sono dentro la sezione, giusta, devo identificare la sezione successiva, che per lui sara una qualunque sezione che cominci con [.
    # nel nostro caso sara una qualunque sezion NON indentata! quindi come occorrenza sara la mancanza degli spazi una stringa seguita da un :.
    # per semplificare il tutto posso appendere pure io una roba... 
     # if within_section:

  #f = os.fdopen(config_file, 'w')
  #f.writelines(yaml_lines)
  #f.close()

  return 0

#______________________________________
def parse_galaxy_yaml():

  options = cli_options()

  do_yaml(options.config_file, options.section, options.option, options.value, 'present')

  # find a section.
  # no indentation


  # find following section


  # search occurrence between line section +1 to next_section -1

  #indentazione
  #cerco la stringa con o senza # e con il : dopo uno spazio
  #gli do la sezione e comincia a leggere dalla ricorrenza fino alla successiva senza indentazione


  #aggiungere che se il file non viene modoficato allora non lo scrive proprio
  return 0

#______________________________________
if __name__ == '__main__':
  parse_galaxy_yaml()
