#!/usr/bin/env python
"""
Python script to modify Galaxy yaml file.
Usage: python parse_galaxy_yaml.py -c galaxy.yml -s uwsgi -o processes -v 4

Derived from ansible ini_file module
https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/files/ini_file.py
All credits to its creators.

GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
"""

import sys, os
import argparse
import re
import tempfile
from shutil import copyfile, move

#______________________________________
def cli_options():
  parser = argparse.ArgumentParser(description='Read and modify galaxy.yaml file')
  parser.add_argument('-c', '--config-file', dest='config_file', help='Load Galaxy yaml file')
  parser.add_argument('-s', '--section', dest='section', help='Set section')
  parser.add_argument('-o', '--option', dest='option', help='Set option')
  parser.add_argument('-v', '--value', dest='value', help='Set value')
  parser.add_argument('--state', dest='state', default='present', help='Set state, if present or abesnt.')
  parser.add_argument('--backup', action='store_true', dest='backup', help='Set if backup has to be saved')
  return parser.parse_args()

#______________________________________
def match_opt(option, line):
  option = re.escape(option)
  return re.match('  ( |\t)*%s( |\t)*(:|$)' % option, line) \
      or re.match('  #( |\t)*%s( |\t)*(:|$)' % option, line) \
      or re.match('  ;( |\t)*%s( |\t)*(:|$)' % option, line)

#______________________________________
def match_active_opt(option, line):
  option = re.escape(option)
  return re.match('  ( |\t)*%s( |\t)*(:|$)' % option, line)

#______________________________________
def do_yaml(config_file, section, option, value, state='present', backup=False):
  """
  Edit yaml file and save it.
  """

  # TODO create file if not exists

  fin = open(config_file, "r")
  try:
    yaml_lines = fin.readlines()
  finally:
    fin.close()

  # If config_file is unmodified, do not write it.
  changed = False

  # append a fake section line to simplify the logic
  yaml_lines.append('foo_control_section:')

  within_section = not section
  section_start = 0

  for index, line in enumerate(yaml_lines):
    if line.startswith('%s:' % section): # find the section
      within_section = True
      section_start = index 
    elif line and line[0].isalpha(): # find end of section
      if within_section:
        if state == 'present':
          for i in range(index, 0, -1):
            # search backwards for previous non-blank or non-comment line
            if not re.match(r'^[  ]*([#;].*)?$', yaml_lines[i - 1]):
              yaml_lines.insert(i, '  %s: %s\n' % (option, value))
              print 'option added'
              changed = True
              break
        elif state == 'absent' and not option:
          # TODO remove the entire section
          print '[warning] TODO'
        break
    # questo else viene visto prima della nuova sezione quindi se trova il match aggiorna la entry ed esce.
    else:
      if within_section and option:
        if state == 'present':
          # change the existing option line
          if match_opt(option, line):
            newline = '  %s: %s\n' % (option, value)
            option_changed = yaml_lines[index] != newline
            changed = changed or option_changed
            if option_changed:
              print 'option changed'
            yaml_lines[index] = newline
            if option_changed:
               # remove all possible option occurrences from the rest of the section
               index = index + 1
               while index < len(yaml_lines):
                 line = yaml_lines[index]
                 if line and line[0].isalpha():
                   break
                 if match_active_opt(option, line):
                   del yaml_lines[index]
                 else:
                    index = index + 1
            break
        elif state == 'absent':
          # TODO delete existing line
          print '[warning] TODO'
          break

  # remove the fake section line
  del yaml_lines[-1:]

  # add section if not present at all
  if not within_section and option and state == 'present':
    yaml_lines.append('%s:\n' % section)
    yaml_lines.append('  %s: %s\n' % (option, value))
    changed = True
    msg = 'section and option added'

  # file is updated only if there are changes.
  if changed:

    # if backup is required it is created
    if backup:
      backupp = os.path.join(os.path.basename(config_file) + ".bak")
      print backupp
      copyfile(config_file, backupp)

    # save changes
    try:
      tmpfd, tmpfile = tempfile.mkstemp()
      f = os.fdopen(tmpfd, 'w')
      f.writelines(yaml_lines)
      f.close()
    except IOError:
      print 'Unable to create temporary file.'

    try:
      move(tmpfile, config_file)
    except IOError:
      print 'Unable to move temporary file %s to %s, IOError' % (tmpfile, filename)

#______________________________________
def parse_galaxy_yaml():

  options = cli_options()

  # TODO allow to read file and identify indentation spaces... this can be done using pyyaml?
  # release_18.05 we currently assume 2 white spaces

  do_yaml(options.config_file, options.section, options.option, options.value, options.state, options.backup)

#______________________________________
if __name__ == '__main__':
  parse_galaxy_yaml()
