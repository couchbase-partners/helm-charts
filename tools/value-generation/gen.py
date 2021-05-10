import yaml
import copy
from emitter import CommentedMapping, CommentedDumper
import sys

# format properties for helm chart
def format_properties(properties, values, comments, sub_keys, depth):
  for key, value in properties.items():

    if 'description' not in value:
      value['description'] = ""

    description = '-- ' + value['description']

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
    comment_map[crd_value] = '-- Controls the generation of the ' + crd_name + ' CRD'
    subkeys=[crd_value]

    # Buckets need some special processing
    if crd_name == 'CouchbaseBucket':
      comment_map[crd_value] = '''-- Disable default bucket creation by setting buckets.default: null
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
      comment_map[tuple(nestedCommentKey)] = '-- Name of the bucket to create.\n@default -- will be filled in as below'
      nestedCommentKey.append('kind')
      comment_map[tuple(nestedCommentKey)] = '''-- The type of the bucket to create by default. 
      Removed from CRD as only used by Helm.'''

    format_properties(crd_properties, values, comment_map, subkeys, 0)

    if crd_name == 'CouchbaseCluster':
      # Some additional fix up we need to do
      value_map[crd_value]['backup']['image'] = 'couchbase/operator-backup:1.0.0'
      value_map[crd_value]['backup']['managed'] = True
      value_map[crd_value]['buckets']['managed'] = True
      value_map[crd_value]['networking']['adminConsoleServices'] = ['data']
      value_map[crd_value]['networking']['exposeAdminConsole'] = True
      value_map[crd_value]['networking']['exposedFeatures'] = [ 'client', 'xdcr' ]
      value_map[crd_value]['security']['rbac']['managed'] = True
      value_map[crd_value]['securityContext']['fsGroup'] = 1000
      value_map[crd_value]['securityContext']['runAsUser'] = 1000
      value_map[crd_value]['securityContext']['runAsNonRoot'] = True
      
      # Admin setup for credentials - not part of CRD so extend
      value_map[crd_value]['security']['username'] = 'Administrator'
      newCommentKey = [crd_value, 'security', 'username']
      comment_map[tuple(newCommentKey)] = '-- Cluster administrator username'
      value_map[crd_value]['security']['password'] = ''
      newCommentKey = [crd_value, 'security', 'password']
      comment_map[tuple(newCommentKey)] = '-- Cluster administrator pasword, auto-generated when empty'
      # For servers we take the name and translate it into a new top-level key
      defaultServer = copy.deepcopy(value_map[crd_value]['servers'])
      # Remove the CRD entry
      value_map[crd_value]['servers'] = {}
      # Override the values
      defaultServer['size'] = 3
      defaultServer['services'] = [ 'data', 'index', 'query', 'search', 'analytics', 'eventing']
      value_map[crd_value]['servers']['default'] = defaultServer
      # Remove name as that is now the top level key
      defaultServer.pop('name', None)
      # Update the comment map as well
      newCommentKey = [crd_value, 'servers', 'default']
      comment_map[tuple(newCommentKey)] = '-- Name for the server configuration. It must be unique.'
      for key in defaultServer:
        newCommentKey= [crd_value, 'servers', 'default', key]
        oldCommentKey = [crd_value, 'servers', key]
        comment_map[tuple(newCommentKey)] = comment_map[tuple(oldCommentKey)]

    # And now, all comments to add default removal too for doc purposes
    

    # convert to documented map
    helm_values = CommentedMapping(value_map, comment='@default -- will be filled in as below', comments=comment_map)

    # dump to stdout
    print(yaml.dump(helm_values, Dumper=CommentedDumper))
