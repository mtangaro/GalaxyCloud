#!/usr/bin/python
'''
Author: Marco Tangaro
mail: ma.tangaro@ibbe.cnr.it
'''

import os, sys
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
  parser.add_argument('-M', '--mount' , action='store_true', help='Mount spaces')
  parser.add_argument('-U', '--umount', action='store_true', help='Umount space')
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
def check_file(fname):
  try:
    with open(fname) as f:
      f.close()
      return True
  except IOError as e:
     print fdefault + ' not found.'
     sys.exit()

#______________________________________
def show_config(fname):
  par = read_config(fname, 'refdata')
  if par:
    print par[0]
    print par[1]
    print par[2]
  upar = read_config(fname, 'userdata')
  if upar:
    print upar[0]
    print upar[1]
    print upar[2]


#______________________________________
def read_config(fname, section):
  configParser = ConfigParser.RawConfigParser()
  configParser.readfp(open(fname))
  configParser.read(fname)

  params = []

  if configParser.has_option(section, 'mountpoint'): 
    params.append(configParser.get(section , 'mountpoint'))
  else:
    print 'Section [' + section + '] not enabled!'
    return

  if configParser.has_option(section, 'provider'):
    params.append(configParser.get(section , 'provider'))
  else:
    print 'No provider specified for section [' + section + ']. Check you configuration file: ' +_fail
    return

  if configParser.has_option(section, 'token'):
    params.append(configParser.get(section , 'token'))
  else:
    print 'No token specified for section [' + section + ']. Check your configuration file:' + _fail
    return

  return params


#______________________________________
def mount_space(fname, section):
  par = read_config(fname, section)
  if par:
    connect(par[1], par[2], par[0])
  else:
    return


#______________________________________
def connect(provider, token, mountpoint):
  command = 'oneclient -H %s -t %s %s' % ( provider, token, mountpoint)
  print command
  subprocess.call( command, shell=True )


#______________________________________
def umount_space(fname, section):
  par = read_config(fname, section)
  if par:
    umount_vol(par[0])
  else:
    return


#______________________________________
def umount_vol(mountpoint):
  command = 'fusermount -u %s' % (mountpoint)
  print command
  subprocess.call( command, shell=True )


#______________________________________
def check_mountpoint(data):
  par = read_ini_file(fdefault, data)
  return os.path.ismount(par[2])

#______________________________________
def onedatactl():

  options = cli_options()

  check_oneclient()

  fileconfig=0

  if options.config_file:
    if check_file(options.config_file): fileconfig = options.config_file
  else:
    fileconfig = fdefault

  if options.mount:
    print fileconfig
    check_file(fileconfig) # Check configuration file
    if options.refdata: mount_space(fileconfig, 'refdata') # Mount reference data
    elif options.userdata: mount_space(fileconfig, 'userdata') # Mount user data
    else:
      mount_space(fileconfig, 'refdata')
      mount_space(fileconfig, 'userdata')

  if options.umount:
    if options.refdata:
      umount_space(fileconfig, 'refdata')
    elif options.userdata:
      umount_space(fileconfig, 'userdata')
    else:
      print 'Volume not found.'


  # check if volume is mounted
  #print check_mountpoint('REFDATA')
  # if oneclient or rest api option is not there, check with fuse if a volume is mounted, then check for referencee data


#______________________________________
if __name__ == '__main__':
  onedatactl()
