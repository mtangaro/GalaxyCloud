'''
testing macro
'''

import argparse
from bioblend.galaxy import GalaxyInstance
from bioblend.galaxy.tools.inputs import inputs

def parse_cli_options():
  parser = argparse.ArgumentParser(description='Download Reference Data', formatter_class=argparse.RawTextHelpFormatter)
  parser.add_argument( '--url', dest='galaxy_url', help='')
  parser.add_argument( '--key', dest='galaxy_key', help='')
  return parser.parse_args()

def get_galaxy_instance(galaxy_url, galaxy_key):
  gi = GalaxyInstance(url=galaxy_url, key=galaxy_key)
  return gi

def start_testing():
  options = parse_cli_options()
  
  gi = get_galaxy_instance(options.galaxy_url, options.galaxy_key)

  list_histories = gi.histories.get_histories()

  test_history = gi.histories.create_history(name='validation')

  role_id = gi.roles.get_roles()[0]['id']

  new_lib = gi.libraries.create_library('my_library')

  gi.libraries.set_library_permissions(new_lib['id'], access_in=[role_id], modify_in=[role_id], add_in=[role_id], manage_in=[role_id])

  list_data = gi.libraries.upload_file_from_url(new_lib['id'], "http://159.149.160.56/indigo_demo/Sc_IP.fastq")

  data_history = gi.histories.upload_dataset_from_library(test_history['id'], list_data[0]['id'])

  fastqc = gi.tools.get_tools(name='fastqc')

  print fastqc
  #detail_tool = gi.tools.show_tool(fastqc[0]['id'], io_details=True)
  #detail_tool['inputs']



if __name__ == "__main__":
  start_testing()
