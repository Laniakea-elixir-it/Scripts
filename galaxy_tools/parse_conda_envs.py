#!/usr/bin/env python
'''
Usage: parse_conda_envs --conda_prefix /home/galaxy/_conda --tool fastqc
'''

import re
import argparse
import subprocess

#______________________________________
def cli_options():
  parser = argparse.ArgumentParser(description='Get specific conda tool env')
  parser.add_argument('-c', '--conda_prefix', dest='conda_prefix', help='Set conda prefix')
  parser.add_argument('-t', '--tool', dest='tool', help='Set tool to find env')
  return parser.parse_args()

#______________________________________
def parse_conda_envs():

  options = cli_options()

  command = '%s/bin/conda env list' % options.conda_prefix
  proc = subprocess.Popen( args=command, shell=True,  stdout=subprocess.PIPE, stderr=subprocess.PIPE )
  communicateRes = proc.communicate()
  stdOutValue, stdErrValue = communicateRes
  status = proc.wait()

  parse = '__%s@([^\s]+)' % options.tool
  find = re.findall(parse, stdOutValue, flags=re.I)

  try:
    assert find
  except AssertionError:
    raise

  print '__' + options.tool + '@' + find[0]

#______________________________________
if __name__ == '__main__':
  parse_conda_envs()
