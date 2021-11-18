import yaml
import copy
from emitter import CommentedMapping, CommentedDumper
import sys
import getopt

# format properties for helm chart
def format_properties(properties, values, comments, sub_keys, depth):
  for key, value in properties.items():

    if 'description' not in value:
      value['description'] = ""

    # Document everything in the YAML but only expose a certain depth in Markdown
    if depth <= 2:
      description = '-- ' + value['description']
    else:
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

      # Now set the default value: we need this to ensure documentation is generated
      values[key] = None
      if 'default' in value:
        values[key] = value['default']
      else:
        # boolean without default is False
        if 'type' in value:
          if value['type'] == 'boolean':
            values[key] = False

def processServiceType(key_prefix, value_map) :
  # ServiceTemplate takes precendence over the depreacated ServiceType so make sure to set it instead.
  serviceType = "NodePort"
  deprecatedKey = key_prefix + 'ServiceType'
  templateKey  = key_prefix + 'ServiceTemplate'

  # Take the current value if it exists and remove it
  if deprecatedKey in value_map:
    serviceType = value_map[deprecatedKey]
    value_map.pop(deprecatedKey, None)

  # Now update the template value or create it
  if templateKey not in value_map:
    value_map[templateKey] = {}
  if 'spec' not in value_map[templateKey]:
    value_map[templateKey]['spec'] = {}
  value_map[templateKey]['spec']['type'] = serviceType

  return value_map[templateKey]

def preProcessBucket(crd_value, value_map, comment_map) :
  # Update top-level comment with extra details
  comment_map[crd_value] = '-- Disable default bucket creation by setting buckets.default: null. Note that setting default to null can throw a warning: https://github.com/helm/helm/issues/5184'
  # We have to nest under a new key
  autoCreatedBucketName = 'default'
  subkeys=[crd_value, autoCreatedBucketName]
  # We now create the nested type and the extra `kind` key not in the CRD
  value_map[crd_value] = { autoCreatedBucketName:
  {
    'kind': 'CouchbaseBucket'
  }}


  # Deal with comments now as a tuple
  nestedCommentKey=[crd_value, autoCreatedBucketName]
  comment_map[tuple(nestedCommentKey)] = '-- Name of the bucket to create.\n@default -- will be filled in as below'
  nestedCommentKey.append('kind')
  comment_map[tuple(nestedCommentKey)] = '''-- The type of the bucket to create by default. Removed from CRD as only used by Helm.'''

  # set default scope resources as empty, since default scope is provided by couchbase
  return value_map[crd_value][autoCreatedBucketName], subkeys


def preProcessRBACResource(kind, crd_value, value_map, comment_map):
  # Key is the lowercase plural spelling of the CRD kind for use by helm chart
  kind_key = kind.lower() + "s"
  # Update top-level comment with extra details
  comment_map[crd_value] = '--  Uncomment to create a "{0}" resource'.format(kind_key)
  # We have to nest a key for the default resource
  autoCreatedName = 'default'
  subkeys=[crd_value, autoCreatedName]
  # We now create the nested type and the extra `kind` key not in the CRD
  value_map[crd_value] = { autoCreatedName:
  {
    'kind': kind
  }}

  # Deal with comments now as a tuple
  nestedCommentKey=[crd_value, autoCreatedName]
  comment_map[tuple(nestedCommentKey)] = '-- Name of the {0} to create.\n@default -- will be filled in as below'.format(kind)

  return value_map[crd_value][autoCreatedName], subkeys


def postProcessScope(crd_value, value_map, comment_map):
  value_map[crd_value]['default']['collections'] = []
  comment_map[(crd_value, 'default', 'collections')] += "\n Ref https://docs.couchbase.com/operator/current/resource/couchbasescope.html#couchbasescopes-spec-collections"

def postProcessScopeGroups(crd_value, value_map, comment_map):
  value_map[crd_value]['default']['names'] = []
  value_map[crd_value]['default']['collections'] = []
  comment_map[(crd_value, 'default', 'collections')] += "\n Ref https://docs.couchbase.com/operator/current/resource/couchbasescopegroup.html#couchbasescopegroups-spec-collections"

def postProcessCollectionGroups(crd_value, value_map, comment_map):
  value_map[crd_value]['default']['names'] = []

def postProcessCluster(crd_value, value_map, comment_map) :
  # Some additional fix up we need to do to align with existing Helm defaults

  # Note that if you set a field to empty map then it may remove nested information
  expectedKeys = ['backup', 'buckets', 'networking', 'security', 'securityContext', 'xdcr' ]
  for expectedKey in expectedKeys:
    if expectedKey not in value_map[crd_value]:
      value_map[crd_value][expectedKey] = {}

  value_map[crd_value]['backup']['image'] = 'couchbase/operator-backup:1.1.0'
  value_map[crd_value]['backup']['managed'] = True

  value_map[crd_value]['buckets']['managed'] = True
  value_map[crd_value]['image'] = 'couchbase/server:6.6.3'
  comment_map[(crd_value, 'backup')] += "  Refer to the documentation for supported values https://docs.couchbase.com/operator/current/howto-backup.html#enable-automated-backup"

  value_map[crd_value]['networking']['adminConsoleServices'] = ['data']
  value_map[crd_value]['networking']['exposeAdminConsole'] = True
  value_map[crd_value]['networking']['exposedFeatures'] = [ 'client', 'xdcr' ]

  # ServiceTemplate takes precendence over the deprecated ServiceType so make sure to set it instead.
  value_map[crd_value]['networking']['adminConsoleServiceTemplate'] = processServiceType('adminConsole', value_map[crd_value]['networking'])
  value_map[crd_value]['networking']['exposedFeatureServiceTemplate'] = processServiceType('exposedFeature', value_map[crd_value]['networking'])

  # Various security updates:
  # TLS must be set up by the chart
  # LDAP requires a lot of configuration if to be used
  value_map[crd_value]['networking'].pop('tls', None)
  value_map[crd_value]['security'].pop('ldap', None)

  if 'rbac' not in value_map[crd_value]['security']:
    value_map[crd_value]['security']['rbac'] = {}
  value_map[crd_value]['security']['rbac']['managed'] = True
  # Default the security context to reasonable values
  value_map[crd_value]['securityContext']['fsGroup'] = 1000
  value_map[crd_value]['securityContext']['sysctls'] = []
  value_map[crd_value]['securityContext']['runAsUser'] = 1000
  value_map[crd_value]['securityContext']['runAsNonRoot'] = True

  # Set this empty to ensure we auto-generate it by default
  value_map[crd_value]['security']['adminSecret'] = ''

  # Set monitoring to emtpy since it requires image which is not provided by default
  value_map[crd_value]['monitoring'] = {}

  # Admin setup for credentials - not part of CRD so extend
  value_map[crd_value]['security']['username'] = 'Administrator'
  newCommentKey = [crd_value, 'security', 'username']
  comment_map[tuple(newCommentKey)] = '-- Cluster administrator username'
  value_map[crd_value]['security']['password'] = ''
  newCommentKey = [crd_value, 'security', 'password']
  comment_map[tuple(newCommentKey)] = '-- Cluster administrator pasword, auto-generated when empty'

  # Additional Helm-only settings
  value_map[crd_value]['name'] = None
  newCommentKey = [crd_value, 'name']
  comment_map[tuple(newCommentKey)] = '-- Name of the cluster, defaults to name of chart release'

  # Removing some alpha features which are disabled by default
  value_map[crd_value]['networking']['adminConsoleServiceTemplate']['spec'].pop('allocateLoadBalancerNodePorts')
  value_map[crd_value]['networking']['exposedFeatureServiceTemplate']['spec'].pop('allocateLoadBalancerNodePorts')
  value_map[crd_value]['securityContext']['windowsOptions'] = {}

  # publishNotReadyAddresses defaults to false and can be removed since it is not forward compatible
  value_map[crd_value]['networking']['exposedFeatureServiceTemplate']['spec'].pop('publishNotReadyAddresses')
  value_map[crd_value]['networking']['adminConsoleServiceTemplate']['spec'].pop('publishNotReadyAddresses')

  # For servers we take the name and translate it into a new top-level key
  defaultServer = {}
  if 'servers' in crd_value:
    defaultServer = copy.deepcopy(value_map[crd_value]['servers'])
  # Remove the CRD entry
  value_map[crd_value]['servers'] = {}
  # Override/provide the values
  defaultServer['autoscaleEnabled'] = False
  defaultServer['size'] = 3
  defaultServer['services'] = [ 'data', 'index', 'query', 'search', 'analytics', 'eventing']
  value_map[crd_value]['servers']['default'] = defaultServer
  # Remove name as that is now the top level key
  defaultServer.pop('name', None)
  # Remove the following as both verbose and kubernetes standard
  value_map[crd_value]['servers']['default']['env'] = []
  value_map[crd_value]['servers']['default']['envFrom'] = []
  value_map[crd_value]['servers']['default']['pod'] = {}
  value_map[crd_value]['servers']['default']['pod']['spec'] = {}
  # Update the comment map as well
  newCommentKey = [crd_value, 'servers', 'default']
  comment_map[tuple(newCommentKey)] = '-- Name for the server configuration. It must be unique.'
  for key in defaultServer:
    newCommentKey= [crd_value, 'servers', 'default', key]
    oldCommentKey = [crd_value, 'servers', key]
    if tuple(oldCommentKey) in comment_map:
      comment_map[tuple(newCommentKey)] = comment_map[tuple(oldCommentKey)]

# drop any keys that do not contain default values or are booleans which default to false
def purge_unset(_dict):
  for key in list(_dict):
    value = _dict[key]
    if 'items' in value:
      if 'properties' in value['items']:
        value = value['items']

    if 'properties' in value:
      purge_unset(value['properties'])
      # The purge_unset call may mean it is now empty so do not include it
      if len(value['properties']) == 0:
        _dict.pop(key)
    else:
      # Remove any without defaults that are not boolean
      if 'default' not in value:
        if 'type' in value:
          if value['type'] != 'boolean':
            _dict.pop(key)
        else:
          _dict.pop(key)
  return _dict

def generate(use_format):

  # Set up a lookup table mapping CRD name to Helm chart YAML key
  # for those we want to auto-generate (all others are skipped)
  crd_mapping = {}

  # rbac format only generates scope and collections values
  if use_format == "rbac":
    crd_mapping['CouchbaseScope'] = 'scopes'
    crd_mapping['CouchbaseScopeGroup'] = 'scopegroups'
    crd_mapping['CouchbaseCollection'] = 'collections'
    crd_mapping['CouchbaseCollectionGroup'] = 'collectiongroups'
  else:
    crd_mapping['CouchbaseCluster']='cluster'
    crd_mapping['CouchbaseBucket']='buckets'

  # Read in crd from stdin
  input_crd = sys.stdin.read()
  for data in yaml.load_all(input_crd, Loader=yaml.Loader) :
    crd_name=data['spec']['names']['kind']
    if crd_name in crd_mapping :
      crd_value=crd_mapping[crd_name]

      crd_properties = data['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']['properties']
      # purge unset properties when using min format
      if use_format == "min":
        crd_properties = purge_unset(crd_properties)

      # value_map - the keys and value extracted from crd
      value_map = {crd_value : {}}

      # comment_map - comments associated with value_map keys
      comment_map = {crd_value : '-- Controls the generation of the ' + crd_name + ' CRD'}

      # values - references the initial values of value_map
      values = value_map[crd_value]

      # subkeys - the initial child keys at current depth
      subkeys=[crd_value]

      # Buckets need some special pre-processing to add some nested types prior to extracting sub-keys
      if crd_name == 'CouchbaseBucket':
        values, subkeys = preProcessBucket(crd_value, value_map, comment_map)

      # RBAC types need pre-processing to prefix nested types with CRD names since helm presents values as maps
      if crd_name == 'CouchbaseScope' or crd_name == 'CouchbaseCollection' or crd_name == 'CouchbaseScopeGroup' or crd_name == 'CouchbaseCollectionGroup':
        values, subkeys = preProcessRBACResource(crd_name, crd_value, value_map, comment_map)

      # Now extract all comments in the right location in the tree
      format_properties(crd_properties, values, comment_map, subkeys, 0)

      # Cluster needs some special processing post extraction to set Helm defaults
      if crd_name == 'CouchbaseCluster':
        postProcessCluster(crd_value, value_map, comment_map)

      if crd_name == 'CouchbaseScope':
        postProcessScope(crd_value, value_map, comment_map)

      if crd_name == 'CouchbaseScopeGroup':
        postProcessScopeGroups(crd_value, value_map, comment_map)

      if crd_name == 'CouchbaseCollectionGroup':
        postProcessCollectionGroups(crd_value, value_map, comment_map)

      # convert to documented map
      helm_values = CommentedMapping(value_map, comment='@default -- will be filled in as below', comments=comment_map)

      # dump to stdout
      print(yaml.dump(helm_values, Dumper=CommentedDumper))

def main(argv):
   # default generating format is full values file
   use_format = "full"
   try:
      opts, args = getopt.getopt(argv,"hf:",["format="])
   except getopt.GetoptError:
      print('gen.py -f <format>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print('gen.py -f <format>')
         sys.exit()
      elif opt in ("-f", "--format"):
         if arg != "full" and arg != "min" and arg != "rbac":
            print('format must be `full` `min` or `rbac`')
            sys.exit(2)
         else:
           use_format = arg

   # generate value file according to provided format
   generate(use_format)

if __name__ == "__main__":
   main(sys.argv[1:])
