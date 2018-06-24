#!/usr/bin/env python
# ELIXIR-ITALY
# INDIGO-DataCloud
# IBIOM-CNR
#
# Contributors:
# author: Tangaro Marco
# email: ma.tangaro@ibiom.cnr.it

# Imports
import argparse

try:
  import ConfigParser
except ImportError:
  import configparse

#______________________________________
def cli_options():
  parser = argparse.ArgumentParser(description='Read ini file')
  parser.add_argument('-c', '--config_file', dest='config_file', help='Load configuration file')
  parser.add_argument('-s', '--section', dest='section', help='Ini file section')
  parser.add_argument('-o', '--option', dest='option', help='Ini file option')
  return parser.parse_args()

#______________________________________
def read_ini_file():

  options = cli_options()

  configParser = ConfigParser.RawConfigParser()
  configParser.readfp(open(options.config_file))
  configParser.read(options.config_file)

  if configParser.has_option(options.section, options.option):
    config = configParser.get(options.section , options.option)
    print config
  else:
    raise Exception('No %s section with %s option in %s' % (options.section, options.option, options.config_file))

#______________________________________
if __name__ == '__main__':
  read_ini_file()
