#!/usr/bin/env python

'''
ELIXIR-ITALY
INDIGO-DataCloud
IBIOM-CNR

Contributors:
author: Tangaro Marco
email: ma.tangaro@ibbe.cnr.it
'''

import socket
import errno
import json

import os
import signal
import time

try:
  import ConfigParser
except ImportError:
  import configparser

import logging
logging.basicConfig(filename='/var/log/galaxy/galaxyctl.log', format='%(levelname)s %(asctime)s %(message)s', level=logging.DEBUG)


####################################

class bcolors:
  HEADER = '\033[95m'
  OKBLUE = '\033[94m'
  OKGREEN = '\033[92m'
  WARNING = '\033[93m'
  FAIL = '\033[91m'
  ENDC = '\033[0m'
  BOLD = '\033[1m'
  UNDERLINE = '\033[4m'

  status_ok = '[ ' + OKGREEN + 'OK' + ENDC + ' ]'
  status_stop = '[ STOP ]'
  status_fail = '[ ' + FAIL + 'FAIL' + ENDC + ' ]'


####################################

class UwsgiStatsServer:
  def __init__(self, server=None, port=None, timeout=None, fname=None):
    self.server = server
    self.port = port
    self.timeout = timeout

    if fname is not None:
      self.fname = fname

      configParser = ConfigParser.RawConfigParser()
      configParser.readfp(open(fname))
      configParser.read(fname)

      section = 'uwsgi'
      option = 'stats'

      if configParser.has_option(section, option):
        self.par = configParser.get(section , option)
        self.server = self.par.split(':')[0]
        self.port = int(self.par.split(':')[1])
      else:
        raise Exception('No [uwsgi] section in %s' % fname)

  #______________________________________
  def GetUwsgiStatsServer(self):

    logging.debug('galaxy_libs.GetUwsgiStatsServer()')
    logging.debug('Waiting Galaxy stats server')
    logging.debug('Timeout: %s' % self.timeout)

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    if self.timeout:
        from time import time as now
        # time module is needed to calc timeout shared between two exceptions
        end = now() + self.timeout

    while True:
      try:
        if self.timeout:
          next_timeout = end - now()
          if next_timeout < 0:
            return False
          else:
            s.settimeout(next_timeout)

        s.connect((self.server, self.port))

      except socket.timeout, err:
        # this exception occurs only if timeout is set
        if self.timeout:
          return False

      except socket.error, err:
        # catch timeout exception from underlying network library
        # this one is different from socket.timeout
        if type(err.args) != tuple or err[0] != errno.ETIMEDOUT:
          pass
      else:
        logging.debug('Stats server enabled on: %s:%s' % (self.server, self.port))
        return s

  #______________________________________
  def GetStatsJson(self):
    reply = self.GetUwsgiStatsServer().recv(131072)
    return reply

  #______________________________________
  # Returns params from *.ini file
  def ReadUwsgiIniFile(self, fname, section, option):
    configParser = ConfigParser.RawConfigParser()
    configParser.readfp(open(fname))
    configParser.read(fname)

    self.par = 0

    if configParser.has_option(section, option):
      self.par = configParser.get(section , option)
    else:
      logging.debug('No [%s] section in %s' % (section, fname))
      return False

    return self.par

  #______________________________________
  # Check if uwsgi workers accept requests or not
  def CheckUwsgiWorkers(self, fname):

    if fname is not None:
      self.fname = fname

    logging.debug('galaxyctl_libs.CheckUwsgiWorkers(fname=%s)' % fname)

    uwsgi_processes = self.ReadUwsgiIniFile(fname, 'uwsgi', 'processes')
    if uwsgi_processes is False:
      return False
    else:
      logging.debug('uWSGI processes: %s' % uwsgi_processes)

    stats_json = self.GetStatsJson()
    stats_dictionary = json.loads(stats_json)

    logging.debug('Check uWSGI workers status')

    for workers in stats_dictionary['workers']:
      workers_id = workers.get('id')
      workers_status = workers.get('accepting')
      workers_pid = workers.get('pid')
      logging.debug('Worker pid: %s' % workers_pid)
      logging.debug('Worker status: %s' %workers_status)
      if workers_status == 1:
        return True

    logging.debug('No uWSGI workers accepting requests')
    return False

  #______________________________________
  def GetBusyList(self, fname=None):

    if fname is not None:
      self.fname = fname

    logging.debug('galaxyctl_libs.GetBusyList(fname=%s)' % fname)

    busy_list = []

    # Get uwsgi workers number
    uwsgi_processes = self.ReadUwsgiIniFile(self.fname, 'uwsgi', 'processes')

    logging.debug('Wait Galaxy stats server on %s:%s' % (self.server, self.port))
    stats = self.GetUwsgiStatsServer()

    if stats:
      stats_json = self.GetStatsJson()
      stats_dictionary = json.loads(stats_json)

      for workers in stats_dictionary['workers']:
        workers_id = workers.get('id')
        workers_status = workers.get('accepting')
        workers_pid = workers.get('pid')
        if workers_status == 0:
          busy_list.append(workers_pid)

      logging.debug('Busy list: %s' % busy_list)
      return busy_list