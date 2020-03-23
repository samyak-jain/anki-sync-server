ankisyncd
=========

[Anki][] is a powerful open source flashcard application, which helps you quickly and easily memorize facts over the long term utilizing a spaced repetition algorithm. Anki's main form is a desktop application (for Windows, Linux and macOS) which can sync to a web version (AnkiWeb) and mobile versions for Android and iOS.

This is a personal Anki server, which you can sync against instead of AnkiWeb. It was originally developed by [David Snopek](https://github.com/dsnopek) It was originally developed to support the flashcard functionality on [Bibliobird](http://en.bibliobird.com), a web application for language learning.

This version is a fork of [jdoe0/ankisyncd](https://github.com/jdoe0/ankisyncd). It supports Python 3 and Anki 2.1.

It also includes a RESTful API, so that you could implement your own AnkiWeb-like site if you wanted.

[Anki]: https://apps.ankiweb.net/
[dsnopek's Anki Sync Server]: https://github.com/dsnopek/anki-sync-server

<details open><summary>Contents</summary>

 - [Installing](#installing)
 - [Installing (Docker)](#installing-docker)
 - [Setting up Anki](#setting-up-anki)
   - [Anki 2.1](#anki-21)
   - [Anki 2.0](#anki-20)
   - [AnkiDroid](#ankidroid)
 - [Running `ankisyncd` without `pyaudio`](#running-ankisyncd-without-pyaudio)
   - [Anki ≥2.1.9](#anki-219)
   - [Older versions](#older-versions)
 - [ENVVAR configuration overrides](#envvar-configuration-overrides)
 - [Support for other database backends](#support-for-other-database-backends)
</details>

Installing the easy way!
------------------------

If you have `easy_install` or `pip` on your system, you can simply run:
```bash
  $ easy_install AnkiServer
```
Or using `pip`:
```bash
  $ pip install AnkiServer
```
This will give you the latest released version!

However, if you want to try the latest bleeding edge version OR you want to help with development, you'll need to install from source. In that case, follow the instructions in the next two sections.

Setting up a virtualenv
-----------------------

If you want to install your Anki Server in an isolated Python environment using [virtualenv](https://pypi.python.org/pypi/virtualenv), please follow these instructions before going on to the next section. If not, just skip to the "Installing" section below.

There are many reasons for installing into a virtualenv, rather than globally on your system:

-  You can keep the Anki Server's dependencies seperate from other Python applications.
-  You don't have permission to install globally on your system (like on a shared host).

Here are step-by-step instruction for setting up your virtualenv:

1. First, you need to install `virtualenv`. If your system has `easy_install` or `pip`, this is just a matter of:
```bash
  $ easy_install virtualenv
```
Or using pip::
```bash
  $ pip install virtualenv
```
Or you can use your the package manager provided by your OS.

2. Next, create your a Python environment for running AnkiServer:
```bash
  $ virtualenv AnkiServer.env
```
3. (Optional) Enter the virtualenv to save you on typing::
```bash
  $ . AnkiServer.env/bin/activate
```

If you skip step 3, you'll have to type `AnkiServer.env/bin/python` instead of `python` and `AnkiServer.env/bin/paster` instead of `paster` in the following sections.

Also, remember that the environment change in step 3 only lasts as long as your current terminal session. You'll have to re-enter the environment if you enter that terminal and come back later.

Installing your Anki Server from source
---------------------------------------

1. Install all the dependencies we need using `easy_install` or
   `pip`:
```bash
  $ easy_install webob PasteDeploy PasteScript sqlalchemy simplejson
```
Or using `pip`:
```bash
  $ pip install webob PasteDeploy PasteScript sqlalchemy simplejson
```
Or you can use your the package manager provided by your OS.

2. Download and install `libanki`. You can find the latest release of Anki here: http://code.google.com/p/anki/downloads/list. Look for a \*.tgz file with a Summary of "Anki Source". At the time of this writing that is `anki-2.0.11.tgz`.

  Download this file and extract. Then either:

  a. Run the `make install`, or

  b. Copy the entire directory to /usr/share/anki

3. Make the egg info files (so paster can see our app):
```bash
  $ python setup.py egg_info
```

Configuring and running your Anki Server
----------------------------------------

1. Copy the example.ini to production.ini in your current directory and edit for your needs.

   a. If you installed from source, it'll be at the top-level.

   b. If you installed via 'easy_install' or 'pip', you'll find all the example configuration at `python_prefix/lib/python2.X/site-packages/AnkiServer-2.X.X-py2.X.egg/examples` (replacing `python_prefix` with the root of your Python and all the `X` with the correct versions). For example, it could be:
   ```bash
   /usr/lib/python2.7/site-packages/AnkiServer-2.0.0a6-py2.7.egg/examples/example.ini
   ```

2. Create user:
```bash
  $ ./ankiserverctl.py adduser <username>
```

3. Test the server by starting it debug mode:
```bash
  $ ./ankiserverctl.py debug
```

If the output looks good, you can stop the server by pressing Ctrl-C and start it again in normal mode:
```bash
  $ ./ankiserverctl.py start
```
To stop AnkiServer, run::
```bash
  $ ./ankiserverctl.py stop
```
Point the Anki desktop program at it
------------------------------------

Unfortunately, there isn't currently any user interface in the Anki destop program to point it at your personal sync server instead of AnkiWeb, so you'll have to write a short "addon".

Create a file like this in your Anki/addons folder called `mysyncserver.py`:
```bash
  import anki.sync
  anki.sync.SYNC_BASE = 'http://127.0.0.1:27701/'
  anki.sync.SYNC_MEDIA_BASE = 'http://127.0.0.1:27701/msync/'
```

Be sure to change the `SYNC_URL` to point at your sync server. The address `127.0.0.1` refers to the local computer.

If you are using TLS, add these lines to the configuration to verify the certificate against a custom certificate chain:
```bash
  # Path to the certificate chain file, relative to the Anki/addons directory
  CERTPATH = 'server.pem'
  
  # Override TLS certificate path
  httpCon_anki = anki.sync.httpCon
  def httpCon_patch():
      import os.path
      conn = httpCon_anki()
    conn.ca_certs = os.path.join(os.path.dirname(__file__), CERTPATH)
    return conn
  anki.sync.httpCon = httpCon_patch
```
The certificate chain must include all intermediate certificates and the root certificate. For the popular free `Let's encrypt <https://letsencrypt.org/>` CA, a sample certificate chain can be found `here <https://gist.github.com/alexander255/a15955932cf9880e77081501feea1345>`.

Unfortunately `python-httplib2` (used by Anki's sync client for issuing HTTP requests) does not support `SNI <https://en.wikipedia.org/wiki/Server_Name_Indication>` for telling the web server during the TLS handshake which certificate to use. This will result in certificate validation errors if your Anki Server instance runs behind a web server that serves multiple domains using different certificates. This has been [fixed](https://github.com/httplib2/httplib2/pull/13) in the `python-httplib2` source code and will be part of the upcoming `0.9.3` release. In the likely event that you are not using the latest version yet you will have to install the latest release from source using:
```bash
  sudo pip install -e git+https://github.com/httplib2/httplib2.git#egg=httplib2
```
Alternatively you can try adding these lines, to disable certificate validation
entirely:
```bash
  # Override TLS certificate path
  httpCon_anki = anki.sync.httpCon
  def httpCon_patch():
    conn = httpCon_anki()
    conn.disable_ssl_certificate_validation = True
    return conn
  anki.sync.httpCon = httpCon_patch
```

Restart Anki for your plugin to take effect. Now, everytime you sync, it will be to your personal sync server rather than AnkiWeb.

However, if you just want to switch temporarily, rather than creating an addon, you can set the `SYNC_URL` environment variable when running from the command-line (on Linux):

```bash
  export SYNC_URL=http://127.0.0.1:27701/sync/
  ./runanki &
```

Point the mobile apps at it
---------------------------

As of AnkiDroid 2.6 the sync server can be changed in the settings:

1. Open the **Settings** screen from the menu
2. In the **Advanced** section, tap on *Custom sync server*
3. Check the **Use custom sync server** box
4. Change the **Sync URL** and **Media sync URL** to the values described above
5. The next sync should use the new sync server (if your previous username
   or password does not match AnkiDroid will ask you to log in again)

At the moment, there isn't any way to get the Anki iOS app to point at
your personal sync server. 😕

Running with Supervisor
-----------------------

If you want to run your Anki server persistantly on a Linux (or
other UNIX-y) server, `Supervisor <http://supervisord.org>`_ is a
great tool to monitor and manage it. It will allow you to start it
when your server boots, restart it if it crashes and easily access
it's logs.

1. Install Supervisor on your system. If it's Debian or Ubuntu this
   will work:
```bash
  $ sudo apt-get install supervisor
```

If you're using a different OS, please try [these instructions](http://supervisord.org/installing.html).

2. Copy `supervisor-anki-server.conf` to `/etc/supervisor/conf.d/anki-server.conf`:
```bash
  $ sudo cp supervisor-anki-server.conf /etc/supervisor/conf.d/anki-server.conf
```
3. Modify `/etc/supervisor/conf.d/anki-server.conf` to match your system and how you setup your Anki Server in the section above.

4. Reload Supervisor's configuration:
```bash
  $ sudo supervisorctl reload
```

5. Check the logs from the Anki Server to make sure everything is fine:
```bash
  $ sudo supervisorctl tail anki-server
```
If it's empty - then everything's fine! Otherwise, you'll see an error message.

Later if you manually want to stop, start or restart it, you can use:
```bash
   $ sudo supervisorctl stop anki-server
```
```bash
   $ sudo supervisorctl start anki-server
```
```bash
   $ sudo supervisorctl restart anki-server
```
See the [Supervisor documentation](http://supervisord.org) for
more info!

Using with Apache
-----------------

If you're already serving your website via Apache (on port 80) and want to also allow users to sync against a URL on port 80, you can forward requests from Apache to the Anki server.

On Bibliobird.com, I have a special anki.bibliobird.com virtual host which users can synch against. Here is an excerpt from my Apache conf:
```
    <VirtualHost *:80>
        ServerAdmin support@lingwo.org
        ServerName anki.bibliobird.com

        # The Anki server handles gzip itself!
        SetEnv no-gzip 1

        <Location />
            ProxyPass http://localhost:27701/
            ProxyPassReverse http://localhost:27701/
        </Location>
    </VirtualHost>
```
It may also be possible to use [mod_wsgi](http://code.google.com/p/modwsgi/), however, I have no experience with that.

Using with nginx
----------------

If you happen to use nginx, you can use the following configuration to proxy requests from nginx to your Anki Server:

```
    server {
        # Allow access via HTTP
        listen 80;
        listen [::]:80;
        
        # Allow access via HTTPS
        listen 443 ssl spdy;
        listen [::]:443 ssl spdy;
        
        # Set server names for access
        server_name anki.server.name;
        
        # Set TLS certificates to use for HTTPS access
        ssl_certificate     /path/to/fullchain.pem;
        ssl_certificate_key /path/to/privkey.pem;
        
        location / {
            # Prevent nginx from rejecting larger media files
            client_max_body_size 0;
            
            proxy_pass http://anki:27701;
            include proxy_params;
        }
    }
```

AnkiDroid will not verify the TLS certificate, Anki Desktop will by default reject all but AnkiWeb's certificate, see the [Anki addon section](#point-the-anki-desktop-program-at-it) for how to change this.

Installing
----------

0. Install Anki. The currently supported version range is 2.1.1〜2.1.11, with the
   exception of 2.1.9<sup id="readme-fn-01b">[1](#readme-fn-01)</sup>. (Keep in
   mind this range only applies to the Anki used by the server, clients can be
   as old as 2.0.27 and still work.) Running the server with other versions might
   work as long as they're not 2.0.x, but things might break, so do it at your
   own risk. If for some reason you can't get the supported Anki version easily
   on your system, you can use `anki-bundled` from this repo:

        $ git submodule update --init
        $ cd anki-bundled
        $ pip install -r requirements.txt

   Keep in mind `pyaudio`, a dependency of Anki, requires development headers for
   Python 3 and PortAudio to be present before running `pip`. If you can't or
   don't want to install these, you can try [patching Anki](#running-ankisyncd-without-pyaudio).

1. Install the dependencies:

        $ pip install webob

2. Modify ankisyncd.conf according to your needs

3. Create user:

        $ ./ankisyncctl.py adduser <username>

4. Run ankisyncd:

        $ python -m ankisyncd

---

<span id="readme-fn-01"></span>
1. 2.1.9 is not supported due to [commit `95ccbfdd3679`][] introducing the
   dependency on the `aqt` module, which depends on PyQt5. The server should
   still work fine if you have PyQt5 installed. This has been fixed in
   [commit `a389b8b4a0e2`][], which is a part of the 2.1.10 release.
[↑](#readme-fn-01b)

[commit `95ccbfdd3679`]: https://github.com/dae/anki/commit/95ccbfdd3679dd46f22847c539c7fddb8fa904ea
[commit `a389b8b4a0e2`]: https://github.com/dae/anki/commit/a389b8b4a0e209023c4533a7ee335096a704079c

Installing (Docker)
-------------------

Follow [these instructions](https://github.com/kuklinistvan/docker-anki-sync-server#usage).

Setting up Anki
---------------

### Anki 2.1

Create a new directory in [the add-ons folder][addons21] (name it something
like ankisyncd), create a file named `__init__.py` containing the code below
and put it in the `ankisyncd` directory.

    import anki.sync, anki.hooks, aqt

    addr = "http://127.0.0.1:27701/" # put your server address here
    anki.sync.SYNC_BASE = "%s" + addr
    def resetHostNum():
        aqt.mw.pm.profile['hostNum'] = None
    anki.hooks.addHook("profileLoaded", resetHostNum)

### Anki 2.0

Create a file (name it something like ankisyncd.py) containing the code below
and put it in `~/Anki/addons`.

    import anki.sync

    addr = "http://127.0.0.1:27701/" # put your server address here
    anki.sync.SYNC_BASE = addr
    anki.sync.SYNC_MEDIA_BASE = addr + "msync/"

[addons21]: https://apps.ankiweb.net/docs/addons.html#_add_on_folders

### AnkiDroid

Advanced → Custom sync server

Unless you have set up a reverse proxy to handle encrypted connections, use
`http` as the protocol. The port will be either the default, 27701, or
whatever you have specified in `ankisyncd.conf` (or, if using a reverse proxy,
whatever port you configured to accept the front-end connection).

**Do not use trailing slashes.**

Even though the AnkiDroid interface will request an email address, this is not
required; it will simply be the username you configured with `ankisyncctl.py
adduser`.

Running `ankisyncd` without `pyaudio`
-------------------------------------

`ankisyncd` doesn't use the audio recording feature of Anki, so if you don't
want to install PortAudio, you can edit some files in the `anki-bundled`
directory to exclude `pyaudio`:

### Anki ≥2.1.9

Just remove "pyaudio" from requirements.txt and you're done. This change has
been introduced in [commit `ca710ab3f1c1`][].

[commit `ca710ab3f1c1`]: https://github.com/dae/anki/commit/ca710ab3f1c1174469a3b48f1257c0fc0ce624bf

### Older versions

First go to `anki-bundled`, then follow one of the instructions below. They all
do the same thing, you can pick whichever one you're most comfortable with.

Manual version: remove every line past "# Packaged commands" in anki/sound.py,
remove every line starting with "pyaudio" in requirements.txt

`ed` version:

    $ echo '/# Packaged commands/,$d;w' | tr ';' '\n' | ed anki/sound.py
    $ echo '/^pyaudio/d;w' | tr ';' '\n' | ed requirements.txt

`sed -i` version:

    $ sed -i '/# Packaged commands/,$d' anki/sound.py
    $ sed -i '/^pyaudio/d' requirements.txt

ENVVAR configuration overrides
------------------------------

Configuration values can be set via environment variables using `ANKISYNCD_` prepended
to the uppercase form of the configuration value. E.g. the environment variable,
`ANKISYNCD_AUTH_DB_PATH` will set the configuration value `auth_db_path`

Environment variables override the values set in the `ankisyncd.conf`.

Support for other database backends
-----------------------------------

sqlite3 is used by default for user data, authentication and session persistence.

`ankisyncd` supports loading classes defined via config that manage most
persistence requirements (the media DB and files are being worked on). All that is
required is to extend one of the existing manager classes and then reference those
classes in the config file. See ankisyncd.conf for example config.


How to get help
---------------

If you're having any problems installing or using Anki Server, please
create an issue on GitHub (or find an existing issue about your problem):

https://github.com/dsnopek/anki-sync-server/issues

Be sure to let us know which operating system and version you're using
and how you intend to use the Anki Server!

