#!/usr/bin/python

import argparse

def cli_options():
  parser = argparse.ArgumentParser(description='Proces actions')
  parser.add_argument('module', help='Load module name')
  parser.add_argument('action', help='Action to be executed')
  return parser.parse_args()

def galaxyctl():
  options = cli_options()
  print options

if __name__ == '__main__':
  galaxyctl()
