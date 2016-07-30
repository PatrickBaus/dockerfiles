<?php
/** NOTE **
 ** Make sure that <?php is the FIRST line of this file!
 ** IE: There should NOT be any blank lines or spaces BEFORE <?php
 **/
/**
 * The phpLDAPadmin config file
 * See: http://phpldapadmin.sourceforge.net/wiki/index.php/Config.php
 * or /usr/share/webapps/phpldapadmin/config/config.php for an example
 */

/*********************************************
 * User-friendly attribute translation       *
 *********************************************/

/* Use this array to map attribute names to user friendly names. For example, if
   you don't want to see "facsimileTelephoneNumber" but rather "Fax". */
// $config->custom->appearance['friendly_attrs'] = array();
$config->custom->appearance['friendly_attrs'] = array(
        'facsimileTelephoneNumber' => 'Fax',
        'gid'                      => 'Group',
        'mail'                     => 'Email',
        'telephoneNumber'          => 'Telephone',
        'uid'                      => 'User Name',
        'userPassword'             => 'Password'
);

/*********************************************
 * Define your LDAP servers in this section  *
 *********************************************/

$servers = new Datastore();

/* $servers->NewServer('ldap_pla') must be called before each new LDAP server
   declaration. */
$servers->newServer('ldap_pla');

/* A convenient name that will appear in the tree viewer and throughout
   phpLDAPadmin to identify this LDAP server to users. */

//NOTE: THIS VALUE WILL BE REPLACED. DO NOT TOUCH
$servers->setValue('server','name','My LDAP Server');

/* Examples:
   'ldap.example.com',
   'ldaps://ldap.example.com/',
   'ldapi://%2fusr%local%2fvar%2frun%2fldapi'
           (Unix socket at /usr/local/var/run/ldap) */
// $servers->setValue('server','host','127.0.0.1');

/* The port your LDAP server listens on (no quotes). 389 is standard. */
// $servers->setValue('server','port',389);

//NOTE: THESE VALUES WILL BE REPLACED. DO NOT TOUCH
$servers->setValue('server','host','127.0.0.1');
$servers->setValue('server','port',389);

/* The DN of the user for phpLDAPadmin to bind with. For anonymous binds or
   'cookie','session' or 'sasl' auth_types, LEAVE THE LOGIN_DN AND LOGIN_PASS
   BLANK. If you specify a login_attr in conjunction with a cookie or session
   auth_type, then you can also specify the bind_id/bind_pass here for searching
   the directory for users (ie, if your LDAP server does not allow anonymous
   binds. */
// $servers->setValue('login','bind_id','');
//NOTE: THIS VALUE WILL BE REPLACED. DO NOT TOUCH
$servers->setValue('login','bind_id','cn=Manager,dc=example,dc=com');
?>
