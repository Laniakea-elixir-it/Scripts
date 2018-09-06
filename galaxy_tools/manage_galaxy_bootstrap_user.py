#!/usr/bin/env python
"""
ELIXIR-ITALY
IBIOM-CNR
Contributors:
author: Tangaro Marco
email: ma.tangaro@ibiom.cnr.it

Script to create and delete galaxy bootstrap user.
This user will be used to install tools.

Script based aon create_galaxy_user.py from John Chilton and adapted to our ansible role
Adapted from https://github.com/galaxyproject/ansible-galaxy-extras/blob/master/templates/create_galaxy_user.py,j2

Usage:
  Crate user: python /usr/local/bin/manage_galaxy_bootstrap_user.py create --user user@server.com --password user_password --username username -c config/galaxy.ini --key api_key
  Delete user: python /usr/local/bin/manage_galaxy_bootstrap_user.py delete --user user@server.com
"""

import sys
sys.path.insert(1,'/home/galaxy/galaxy')
sys.path.insert(1,'/home/galaxy/galaxy/lib')

from galaxy.model import User, APIKeys, Role
from galaxy.model.mapping import init
from galaxy.model.orm.scripts import get_config
import argparse

#______________________________________
def cli_options():
    parser = argparse.ArgumentParser(description='Delete galaxy users')
    parser.add_argument('-c', '--config-file', dest='config_file', help='Galaxy configuration file')

    subparsers = parser.add_subparsers(title="action", help='create or delete bootstrap users')
    parser_create = subparsers.add_parser('create', help='create a new bootstrap user')
    parser_create.set_defaults(action='create')
    parser_create.add_argument("-u", "--user", dest="user", required=True, help="Username, it should be an email address.")
    parser_create.add_argument("-p", "--password", required=True, help="Password.")
    parser_create.add_argument("-a", "--key", help="API-Key.")
    parser_create.add_argument("-n", "--username", default="admin", help="The public username. Public names must be at least three characters in length and contain only lower-case letters, numbers, and the '-' character.")

    parser_delete = subparsers.add_parser('delete', help='Delete an existing bootstrap user')
    parser_delete.set_defaults(action='delete')
    parser_delete.add_argument('-u', '--user',  dest='user', help='User to delete')

    return parser.parse_args()

#______________________________________
def delete_user(sa_session, security_agent, email):
    """
        Delete Galaxy User.
    """

    # This commented code is needed to correctly delete user created with default permmissions
    # i.e. histories and datasets
    #query = sa_session.query( User ).filter_by( email=email )
    #user = query.first()
    #user_id = user.id
    #print 'user_id: %s' % user_id 

    #query_role = sa_session.query( Role ).filter_by( name=email )
    #role =  query_role.first()
    #role_id = role.id
    #print 'role_id: %s' % role_id

    #print 'Deleting user_default_permissions'
    #query_user_default_permissions = sa_session.query( DefaultUserPermissions ).filter_by( user_id=user_id, role_id=role_id )
    #user_default_permissions = query_user_default_permissions.first()
    #user_default_permissions_id = user_default_permissions.id
    #print user_default_permissions.id
    #sa_session.delete(user_default_permissions)
    #sa_session.flush()

    #print 'Deleting user_role_association'
    #query_role_association = sa_session.query( UserRoleAssociation ).filter_by( user_id=user_id, role_id=role_id )
    #role_association = query_role_association.first()
    #role_association_id = role_association.id
    #print role_association_id
    #sa_session.delete(role_association)
    #sa_session.flush()

    # delete before the role associated to the user.
    query_role = sa_session.query( Role ).filter_by( name=email )
    if query_role.count() > 0:
      role = query_role.first()
      sa_session.delete(role)
      sa_session.flush()
    else:
      print 'No role found for user %s' % email

    query = sa_session.query( User ).filter_by( email=email )
    if query.count() > 0:
      user = query.first()
      sa_session.delete(user)
      sa_session.flush()
    else:
      print 'No user %s found' % email
      #raise Exception('No user %s found' % email)

#______________________________________
def add_user(sa_session, security_agent, email, password, key=None, username="admin"):
    """
        Add Galaxy User.
        From John https://gist.github.com/jmchilton/4475646
    """
    query = sa_session.query( User ).filter_by( email=email )
    if query.count() > 0:
        return query.first()
    else:
        User.use_pbkdf2 = True
        user = User(email)
        user.username = username
        user.set_password_cleartext(password)
        sa_session.add(user)
        sa_session.flush()

        security_agent.create_private_user_role( user )
        # bootstrap user don't need history and datasets permissions
        # to install tools. We comment this out
        #if not user.default_permissions:
        #    security_agent.user_set_default_permissions( user, history=True, dataset=True )

        if key is not None:
            api_key = APIKeys()
            api_key.user_id = user.id
            api_key.key = key
            sa_session.add(api_key)
            sa_session.flush()
        return user

#______________________________________
def manage_galaxy_bootstrap_user():

    db_url = get_config(sys.argv, use_argparse=False)['db_url']

    options = cli_options()
  
    mapping = init('/tmp/', db_url)
    sa_session = mapping.context
    security_agent = mapping.security_agent

    if options.action == "create":
      add_user(sa_session, security_agent, options.user, options.password, key=options.key, username=options.username)
    elif options.action == "delete":
      delete_user(sa_session, security_agent, options.user)
 
#______________________________________
if __name__ == "__main__":
   manage_galaxy_bootstrap_user()
