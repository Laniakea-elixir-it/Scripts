#!/usr/bin/env python
"""
ELIXIR-ITALY
IBIOM-CNR

Contributors:
author: Tangaro Marco
email: ma.tangaro@ibiom.cnr.it
"""

# Imports
import os
import argparse

#______________________________________
def cli_options():
  parser = argparse.ArgumentParser(description='Read Galaxy config file')
  parser.add_argument('-c', '--config_file', dest='config_file', help='Load configuration file')
  parser.add_argument('-s', '--section', dest='section', help='Ini file section')
  parser.add_argument('-o', '--option', dest='option', help='Ini file option')
  return parser.parse_args()

#______________________________________
def read_galaxy_config_file():

  options = cli_options()

  filename, file_extension = os.path.splitext(options.config_file)
  file_extension = file_extension.replace('.', '')

  if file_extension == 'ini':

    try:
      import ConfigParser
    except ImportError:
      import configparse

    configParser = ConfigParser.RawConfigParser()
    configParser.readfp(open(options.config_file))
    configParser.read(options.config_file)

    if configParser.has_option(options.section, options.option):
      config = configParser.get(options.section , options.option)
      print (config)
    else:
      raise Exception('No %s section with %s option in %s' % (options.section, options.option, options.config_file))

  elif file_extension == 'yml' or file_extension == 'yaml':

    import yaml
    with open(options.config_file, 'r') as stream:
      try:
        config =  yaml.safe_load(stream)
        par = config[options.section][options.option]
        print (par)
      except yaml.YAMLError as exc:
        raise Exception('No %s section with %s option in %s' % (options.section, options.option, options.config_file))

#______________________________________
if __name__ == '__main__':
  read_galaxy_config_file()
