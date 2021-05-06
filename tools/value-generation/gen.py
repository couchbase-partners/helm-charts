import yaml
import copy
from emitter import CommentedMapping, CommentedDumper


# format properties for helm chart
def format_properties(properties, values, comments, sub_keys, depth):
  for key, value in properties.items():

    if 'description' not in value:
      value['description'] = ""

    
    description = value['description']

    if 'items' in value:
      if 'properties' in value['items']:
        value = value['items']

    # check for sub properties 
    if 'properties' in value:
      values[key] = {}

      # place comment key at whatever depth we are in
      subs = copy.deepcopy(sub_keys)
      subs.append(key)
      comments[tuple(subs)] = description
      format_properties(value['properties'], values[key], comments, subs, depth + 1)

    else:
      comment_key = key 
      if len(sub_keys):
        subs = copy.deepcopy(sub_keys)
        subs.append(key)
        comment_key = tuple(subs)

      # populate description and default value
      # comment keys are tuple
      comments[comment_key] = description
      if 'default' in value:
        values[key] = value['default']
      else:
        # boolean without default is False
        if 'type' in value:
          if value['type'] == 'boolean':
            values[key] = False 
        values[key] = None 


# read in crd properties - TODO: read from stdin
in_stream = open('crd.yaml', 'r')

for data in yaml.load_all(in_stream, Loader=yaml.Loader) :
  crd_name=data['spec']['names']['kind']
  # if 'CouchbaseClusterXXX' in crd_name :
  crd_properties = data['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']['properties']

  # pass properties into formatter
  value_map = {}
  comment_map = {}
  sub_keys = ('cluster',)
  format_properties(crd_properties, value_map, comment_map, [], 0)

  # reorganize
  # TODO

  # convert to documented map
  helm_values = CommentedMapping(value_map, comment='Couchbase Operator Chart Values for '+crd_name, comments=comment_map)

  # dump to stdout
  print(yaml.dump(helm_values, Dumper=CommentedDumper))
