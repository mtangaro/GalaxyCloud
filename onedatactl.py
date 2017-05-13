#!/usr/bin/python
'''
Author: Marco Tangaro
mail: ma.tangaro@ibbe.cnr.it
'''

import argparse
import subprocess

def cli_options():
  parser = argparse.ArgumentParser(description='Onedata connection script')
  parser.add_argument('-r', '--refdata', action='store_true', help='Reference Data')
  parser.add_argument('-u', '--userdata', action='store_true', help='User Data')
  parser.add_argument('-t', '--token', dest='token', help='Access token')
  parser.add_argument('-p', '--provider', dest='provider', help='Action to be executed')
  parser.add_argument('-m', '--mountpoint', dest='mountpoint', help='Set mountpoint')
  parser.add_argument('-c', help='Load configuration file')
  return parser.parse_args()

#______________________________________
def check_oneclient():
  try:
    subprocess.call(['oneclient', '--version'])
  except OSError as e:
    if e.errno == os.errno.ENOENT:
      # handle oneclient not found error.
      print 'Oneclient is not installed on your system. Please install it: https://onedata.org/docs/doc/using_onedata/oneclient.html'
    else:
        # Something else went wrong while trying to run `wget`
      print 'Unable to test Oneclient'
      raise

#______________________________________
def connect(provider_hostname, access_token, mountpoint):
  command = 'oneclient -H %s -t %s %s' % ( provider_hostname, access_token, mountpoint)
  print command
  subprocess.call( command, shell=True )

def onedatactl():
  options = cli_options()
  check_oneclient()

  connect(options.provider, options.token, options.mountpoint)

  #print options

if __name__ == '__main__':
  onedatactl()
