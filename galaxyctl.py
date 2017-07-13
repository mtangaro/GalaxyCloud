#!/usr/bin/env python

'''
ELIXIR-ITALY
INDIGO-DataCloud
IBIOM-CNR

Contributors:
author: Tangaro Marco
email: ma.tangaro@ibiom.cnr.it
'''

import sys, os
import time
import argparse

# Custom libraries
from galaxyctl_libs import UwsgiStatsServer
from galaxyctl_libs import bcolors

galaxy_config_file = '/home/galaxy/galaxy/config/galaxy.ini'

#______________________________________
def cli_options():
  parser = argparse.ArgumentParser(description='Onedata connection script')
  parser.add_argument('options', nargs='*', help='OPTIONS')
  parser.add_argument('-f', '--force', action='store_true', dest='force', default=False, help='Force Galaxy to start')
  parser.add_argument('-c', '--config-file', dest='config_file', help='uWSGI ini file')
  parser.add_argument('-s', '--server', dest='server', type=str, help='Server address')
  parser.add_argument('-p', '--port', dest='port', type=int, help='Server port')
  parser.add_argument('-t', '--timeout', dest='timeout', default=300, help='Wait timeout')
  return parser.parse_args()

#______________________________________
# Galaxy startup: Wait galaxy to start and restart Galaxy 5 times before error.
def startup_galaxy(ini_file='/home/galaxy/galaxy/config/galaxy.ini', wait_time=300):

  galaxy_startup_check(ini_file, wait_time)

#______________________________________
def stop_galaxy(ini_file='/home/galaxy/galaxy/config/galaxy.ini'):

  stats = UwsgiStatsServer(timeout=5, fname=ini_file)
  busy_list = stats.GetBusyList()

  os.system('supervisorctl stop galaxy:')

  if busy_list:
    print busy_list
    kill_command = 'kill -9 %s' % (' '.join( repr(e) for e in busy_list))
    os.system(kill_command)

  print bcolors.status_ok

#______________________________________
def start_galaxy(ini_file='/home/galaxy/galaxy/config/galaxy.ini', wait_time=300):

  os.system('supervisorctl start galaxy:')

  # Wait Galaxy start
  stats = UwsgiStatsServer(timeout=wait_time, fname=ini_file)
  socket = stats.GetUwsgiStatsServer()
  if socket is False:
    print bcolors.status_fail
    return
  else:
    socket.close()  

  # Wait workers accepting requests
  time.sleep(5)
  
  status = False
  status = stats.CheckUwsgiWorkers(ini_file)

  if status is True:
    print bcolors.status_ok
    return

  # check workers 5 times before raise error
  retries = 0
  while status is False:
    time.sleep(2)
    status = stats.CheckUwsgiWorkers(ini_file)
    retries += 1
    if status is True:
      print bcolors.status_ok
      break
    if retries == 5:
      sys.exit('[Error] Start failed. Check log files!')
      print bcolors.status_fail
      break

#______________________________________
# Try to restart Galaxy 5 times before error
def force_start_galaxy(ini_file='/home/galaxy/galaxy/config/galaxy.ini', wait_time=300):

  start_galaxy(ini_file, wait_time)
  galaxy_startup_check(ini_file, wait_time)
  
#______________________________________
def galaxy_startup_check(ini_file='/home/galaxy/galaxy/config/galaxy.ini', wait_time=300):
  
  stats = UwsgiStatsServer(timeout=wait_time, fname=ini_file)
  server = stats.GetUwsgiStatsServer()

  status = False
  retries = 0
  status = stats.CheckUwsgiWorkers(ini_file)
  while status is False:
    time.sleep(5) # pause to let workers accept requests
    restart_galaxy()
    status = stats.CheckUwsgiWorkers(ini_file)
    retries += 1
    if status is True:
      print 'Workers check: ' + bcolors.status_ok
      break
    if retries == 5:
      sys.exit('[Error] Start failed. Check log files!')
      print bcolors.status_fail
      break

#______________________________________
def restart_galaxy(ini_file='/home/galaxy/galaxy/config/galaxy.ini', wait_time=300):
  stop_galaxy(ini_file)
  start_galaxy(ini_file, wait_time)

#______________________________________
def force_restart_galaxy(ini_file='/home/galaxy/galaxy/config/galaxy.ini', wait_time=300):
  stop_galaxy(ini_file)
  force_start_galaxy(ini_file, wait_time)

#______________________________________
def status_galaxy():
  os.system('supervisorctl status galaxy:')

#______________________________________
def galaxyctl():

  options = cli_options()

  # Replace galaxy_config_file if needed
  if options.config_file:
    global galaxy_config_file
    galaxy_config_file = options.config_file

  # Timeout needs to be float. We cast it here!
  # We cannot declare it as float using argparse default type otherwise we loose the possibility to set it to None!
  if options.timeout is not None:
    options.timeout = float(options.timeout)

  if sys.argv[1] == 'galaxy-startup':
    startup_galaxy(galaxy_config_file, options.timeout)

  if sys.argv[1] == 'stop' and sys.argv[2] == 'galaxy':
    print 'Stopping Galaxy: '
    stop_galaxy(galaxy_config_file)

  if sys.argv[1] == 'start' and sys.argv[2] == 'galaxy':
    print 'Starting Galaxy: '
    if options.force is True:
      force_start_galaxy( galaxy_config_file, options.timeout )
    else:
      start_galaxy( galaxy_config_file, options.timeout )

  if sys.argv[1] == 'restart' and sys.argv[2] == 'galaxy':
    print 'Restarting Galaxy:'
    if options.force is True:
      force_restart_galaxy( galaxy_config_file, options.timeout )
    else:
      restart_galaxy( galaxy_config_file, options.timeout )

  if sys.argv[1] == 'status' and sys.argv[2] == 'galaxy':
    status_galaxy()

#______________________________________
if __name__ == '__main__':
  galaxyctl()
