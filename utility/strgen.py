#!/usr/bin/env python

import argparse
import random

from string import ascii_letters, digits, ascii_lowercase
alphanum = ascii_letters + digits

#______________________________________
def cli_options():

  parser = argparse.ArgumentParser(description='INDIGO PaaS checker status')

  parser.add_argument('-l', dest='length', help='Sting length')

  return parser.parse_args()


#______________________________________
def create_random_string(length):
  return ''.join([random.choice(alphanum) for i in range(length)])

#______________________________________
def strgen():

  options = cli_options()

  print( create_random_string(int(options.length)) )

#______________________________________
if __name__ == '__main__':
  strgen()
