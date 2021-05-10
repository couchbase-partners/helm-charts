import yaml
import copy
from emitter import CommentedMapping, CommentedDumper
import sys

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

      # Limit the depth we descend to
      if depth < 2:
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

      # Now set the default value
      values[key] = None 
      if 'default' in value:
        values[key] = value['default']
      else:
        # boolean without default is False
        if 'type' in value:
          if value['type'] == 'boolean':
            values[key] = False
          # Other supported types are string, integer, array and object

# Set up a lookup table mapping CRD name to Helm chart YAML key
crd_mapping = {}
crd_mapping['CouchbaseCluster']='cluster'
crd_mapping['CouchbaseBucket']='buckets'

# read in crd properties from stdin
input_crd = sys.stdin.read()

for data in yaml.load_all(input_crd, Loader=yaml.Loader) :
  crd_name=data['spec']['names']['kind']
  if crd_name in crd_mapping :
    crd_value=crd_mapping[crd_name]
    
    crd_properties = data['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']['properties']

    # pass properties into formatter
    value_map = {}
    value_map[crd_value] ={}
    values=value_map[crd_value]
    comment_map = {}
    comment_map[crd_value] = 'Controls the generation of the ' + crd_name + ' CRD'
    subkeys=[crd_value]

    # Buckets need some special processing
    if crd_name == 'CouchbaseBucket':
      comment_map[crd_value] = '''disable default bucket creation by setting buckets.default: null
      setting default to null can throw warning https://github.com/helm/helm/issues/5184'''
      # We have to nest under a new key
      autoCreatedBucketName = 'default'
      subkeys=[crd_value, autoCreatedBucketName]
      # We now create the nested type and the extra `kind` key not in the CRD
      value_map[crd_value] = { autoCreatedBucketName: 
      {
        'kind': 'CouchbaseBucket'
      }}
      values = value_map[crd_value][autoCreatedBucketName]

      # Deal with comments now as a tuple
      nestedCommentKey=[crd_value, autoCreatedBucketName]
      comment_map[tuple(nestedCommentKey)] = 'Name of the bucket to create.'
      nestedCommentKey.append('kind')
      comment_map[tuple(nestedCommentKey)] = '''The type of the bucket to create by default. 
      Removed from CRD as only used by Helm.'''
    
    format_properties(crd_properties, values, comment_map, subkeys, 0)

    # convert to documented map
    helm_values = CommentedMapping(value_map, comments=comment_map)

    # dump to stdout
    print(yaml.dump(helm_values, Dumper=CommentedDumper))
