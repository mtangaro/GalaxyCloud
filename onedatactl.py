#!/usr/bin/python
'''
Author: Marco Tangaro
mail: ma.tangaro@ibbe.cnr.it
'''

import argparse
import subprocess
import ConfigParser

fdefault = '/etc/galaxy/onedatactl.ini'

#______________________________________
def cli_options():
  parser = argparse.ArgumentParser(description='Onedata connection script')
  parser.add_argument('-r', '--refdata', action='store_true', help='Reference Data')
  parser.add_argument('-u', '--userdata', action='store_true', help='User Data')
  parser.add_argument('-t', '--token', dest='token', help='Access token')
  parser.add_argument('-H', '--provider', dest='provider', help='Action to be executed')
  parser.add_argument('-m', '--mountpoint', dest='mountpoint', help='Set mountpoint')
  parser.add_argument('-c', dest='config_file', help='Load configuration file')
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
def check_ini_file(fname):
  try:
    with open(fname) as ftest:
      ftest.close()
      return True
  except IOError as e:
     return False

#______________________________________
def read_ini_file(fname, section):
  configParser = ConfigParser.RawConfigParser()
  configParser.readfp(open(fname))
  configParser.read(fname)
  provider = configParser.get(section , 'provider')
  token = configParser.get(section , 'token')
  mountpoint = configParser.get(section , 'mountpoint')
  params = [provider, token, mountpoint]
  return params


#______________________________________
def load_data(fname, section):
  par = read_ini_file(fname, section)
  connect(par[0], par[1], par[2])


#______________________________________
def connect(provider_hostname, access_token, mountpoint):
  command = 'oneclient -H %s -t %s %s' % ( provider_hostname, access_token, mountpoint)
  print command
  subprocess.call( command, shell=True )


#______________________________________
def load_from_file(fname, refdata, userdata):
  if check_ini_file(fname):
    if refdata: load_data(fname, 'REFDATA')
    if userdata: load_data(fname, 'USERDATA')

  elif check_ini_file(fdefault):
    print 'Loading default options from' + fdefault
    if refdata: load_data(fdefault, 'REFDATA')
    if userdata: load_data(fdefault, 'USERDATA')

  else:
    print 'Unable to load configuration file. Please load Onedata parameters manually'
    return


#______________________________________
def onedatactl():

  options = cli_options()

  check_oneclient()

  if options.config_file:
    load_from_file(options.config_file, options.refdata, options.userdata)
  else:
    print 'load manually'


  # check if volume is mounted
  # if oneclient or rest api option is not there, check with fuse if a volume is mounted, then check for referencee data


#______________________________________
if __name__ == '__main__':
  onedatactl()
