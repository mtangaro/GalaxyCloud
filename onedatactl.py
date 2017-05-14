#!/usr/bin/python
'''
Author: Marco Tangaro
mail: ma.tangaro@ibbe.cnr.it
'''

import os
import argparse
import subprocess

try:
  import ConfigParser
except ImportError:
  import configparser

fdefault = '/etc/galaxy/onedatactl.ini'

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# ok and fail variables
_ok = '[ ' + bcolors.OKGREEN + 'OK' + bcolors.ENDC + ' ]'
_stop = '[ STOP ]'
_fail = '[ ' + bcolors.FAIL + 'FAIL' + bcolors.ENDC + ' ]'


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
def check_configuration(fname):
  par = read_ini_file(fname, 'refdata')
  if par:
    print par[0]
    print par[1]
    print par[2]
  upar = read_ini_file(fname, 'userdata')
  if upar:
    print upar[0]
    print upar[1]
    print upar[2]


#______________________________________
def read_ini_file(fname, section):
  configParser = ConfigParser.RawConfigParser()
  configParser.readfp(open(fname))
  configParser.read(fname)

  params = []

  if configParser.has_option(section, 'mountpoint'): 
    params.append(configParser.get(section , 'mountpoint'))
  else:
    print 'Section [' + section + '] not enabled!'
    return False

  if configParser.has_option(section, 'provider'):
    params.append(configParser.get(section , 'provider'))
  else:
    print 'No provider specified. Check you configuration file: ' +_fail
    return

  if configParser.has_option(section, 'token'):
    params.append(configParser.get(section , 'token'))
  else:
    print 'No token specified. Check your configuration file:' + _fail
    return

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
    print 'Unable to find configuration file. Loading default options from' + fdefault
    if refdata: load_data(fdefault, 'REFDATA')
    if userdata: load_data(fdefault, 'USERDATA')

  else:
    print 'Unable to load configuration file. Please check your configuration or load Onedata parameters manually!'
    return

#______________________________________
def load_config(fname, data):
  if check_ini_file(fname):
    load_data(fname, data)

  elif check_ini_file(fdefault):
    print 'Unable to find configuration file. Loading default options from' + fdefault
    load_data(fdefault, data)

  else:
    print 'Unable to load configuration file. Please check your configuration or load Onedata parameters manually!'
    return


#______________________________________
def check_mountpoint(data):
  par = read_ini_file(fdefault, data)
  return os.path.ismount(par[2])

#______________________________________
def onedatactl():

  options = cli_options()

  check_oneclient()

  check_configuration(options.config_file)

  #---
  # Reference data section
#  if 
#
#  if options.config_file:
#    load_from_file(options.config_file, options.refdata, options.userdata)
#  else:
#    if options.refdata: connect(options.provider, options.token, options.mountpoint)
#    if options.userdata: connect(options.provider, options.token, options.mountpoint)


#  # Mount volumes
#  if options.config_file:
#    load_from_file(options.config_file, options.refdata, options.userdata)
#  else:
#    if options.refdata: connect(options.provider, options.token, options.mountpoint)
#    if options.userdata: connect(options.provider, options.token, options.mountpoint)


  # check if volume is mounted
  #print check_mountpoint('REFDATA')
  # if oneclient or rest api option is not there, check with fuse if a volume is mounted, then check for referencee data


#______________________________________
if __name__ == '__main__':
  onedatactl()
