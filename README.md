# nginx unit tools

[Nginx Unit](https://github.com/nginx/unit) and [Nginx Unit Documentation](http://unit.nginx.org/docs-nginx-unit.html).

Install commands on CentOS 7.4 64bit for Centmin Mod 123.09beta01 LEMP Stack based servers

```
mkdir -p /root/tools
git clone https://github.com/centminmod/centminmod-nginx-unit
cd centminmod-nginx-unit
tools/nginx-unit-tools.sh install-unit
```

Once installed, save your Nginx Unit json config files in `/root/tools/unitconfigs` and then run `merge-json` option to get a command you run to load your json configs into Nginx Unit.

Optionally enable multiple PHP and Python version support if you're on Centmin Mod 123.09beta01 LEMP stack installed servers via variables within `tools/nginx-unit-tools.sh`:

```
MULTI_PHPVER='y'
PYTHONTHREEFOUR='y'
PYTHONTHREEFIVE='y'
PYTHONTHREESIX='y'
```

```
ls -lah /opt/unit/modules
total 900K
drwxr-xr-x 2 root root 4.0K Sep 28 04:02 .
drwxr-xr-x 5 root root   67 Sep 28 04:02 ..
-rwxr-xr-x 1 root root 110K Sep 28 04:02 iuspython34.unit.so
-rwxr-xr-x 1 root root 110K Sep 28 04:02 iuspython35.unit.so
-rwxr-xr-x 1 root root 111K Sep 28 04:02 iuspython36.unit.so
-rwxr-xr-x 1 root root  89K Sep 28 04:02 php5.6.31.unit.so
-rwxr-xr-x 1 root root 104K Sep 28 04:02 python.unit.so
-rwxr-xr-x 1 root root  89K Sep 28 04:02 remiphp56.unit.so
-rwxr-xr-x 1 root root  88K Sep 28 04:02 remiphp70.unit.so
-rwxr-xr-x 1 root root  89K Sep 28 04:02 remiphp71.unit.so
-rwxr-xr-x 1 root root  90K Sep 28 04:02 remiphp72.unit.so
```

```
tail -100 /var/log/unitd.log 
2017/09/28 04:02:31 [info] 8563#8563 discovery started
2017/09/28 04:02:31 [notice] 8563#8563 module: python 3.4.7 "/opt/unit/modules/iuspython34.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 module: python 3.5.4 "/opt/unit/modules/iuspython35.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 module: python 3.6.2 "/opt/unit/modules/iuspython36.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 module: php 5.6.31 "/opt/unit/modules/php5.6.31.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 module: python 2.7.5 "/opt/unit/modules/python.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 module: php 5.6.31 "/opt/unit/modules/remiphp56.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 ignoring /opt/unit/modules/remiphp56.unit.so module with the same application language version php 5.6.31 as in /opt/unit/modules/php5.6.31.unit.so
2017/09/28 04:02:31 [notice] 8563#8563 module: php 7.0.24 "/opt/unit/modules/remiphp70.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 module: php 7.1.10 "/opt/unit/modules/remiphp71.unit.so"
2017/09/28 04:02:31 [notice] 8563#8563 module: php 7.2.0RC3 "/opt/unit/modules/remiphp72.unit.so"
2017/09/28 04:02:31 [info] 8566#8566 controller started
2017/09/28 04:02:31 [info] 8567#8567 router started
```

# Merging JSON Configs

For merging a directory of Nginx Unit json config files into one json config for loading into Nginx Unit API

Example

`merge-json` option takes all json config files saved in `/root/tools/unitconfigs` and generates a command you can use leveraging `jq` to merge all `.json` extension based json config files into a single json format file to piping into Nginx unit

```
ls -lah /root/tools/unitconfigs/ 
total 20K
drwxr-xr-x  2 root root  101 Sep 24 09:38 .
drwxr-xr-x. 7 root root 4.0K Sep 24 02:40 ..
-rw-r--r--  1 root root  404 Sep 24 00:55 php5631start.json
-rw-r--r--  1 root root  404 Sep 24 00:59 php7024start.json
-rw-r--r--  1 root root  404 Sep 24 01:27 php7110start.json
-rw-r--r--  1 root root  403 Sep 24 00:59 php720start.json
```

Run command from `/root/tools/unitconfigs` directory

```
cd /root/tools/unitconfigs
/root/tools/unittools/nginx-unit-tools.sh merge-json
jq -s '.[0] * .[1] * .[2] * .[3]' php5631start.json php7024start.json php720start.json php7110start.json  | curl -X PUT -d@- --unix-socket /opt/unit/control.unit.sock http://localhost
```

running the generated command

```
jq -s '.[0] * .[1] * .[2] * .[3]' php5631start.json php7024start.json php720start.json php7110start.json  | curl -X PUT -d@- --unix-socket /opt/unit/control.unit.sock http://localhost
{
        "success": "Reconfiguration done."
}
```

checking Nginx unit loaded configurations

```
curl --unix-socket /opt/unit/control.unit.sock http://localhost/
{
        "listeners": {
                "*:8300": {
                        "application": "php56domaincom"
                },

                "*:8400": {
                        "application": "php70domaincom"
                },

                "*:8600": {
                        "application": "php72domaincom"
                },

                "*:8500": {
                        "application": "php71domaincom"
                }
        },

        "applications": {
                "php56domaincom": {
                        "type": "php 5.6.31",
                        "workers": 20,
                        "root": "/home/nginx/domains/domain.com/public",
                        "user": "nginx",
                        "group": "nginx",
                        "index": "index.php"
                },

                "php70domaincom": {
                        "type": "php 7.0.24",
                        "workers": 20,
                        "root": "/home/nginx/domains/domain.com/public",
                        "user": "nginx",
                        "group": "nginx",
                        "index": "index.php"
                },

                "php72domaincom": {
                        "type": "php 7.2.0",
                        "workers": 20,
                        "root": "/home/nginx/domains/domain.com/public",
                        "user": "nginx",
                        "group": "nginx",
                        "index": "index.php"
                },

                "php71domaincom": {
                        "type": "php 7.1.10",
                        "workers": 20,
                        "root": "/home/nginx/domains/domain.com/public",
                        "user": "nginx",
                        "group": "nginx",
                        "index": "index.php"
                }
        }
}
```

```
root       966  0.0  0.0  16032   820 ?        Ss   09:26   0:00 unit: main [/opt/unit/sbin/unitd]
nginx     1078  0.0  0.0  26276   796 ?        S    09:26   0:00  \_ unit: controller
nginx     1080  0.0  0.0 403428  1432 ?        Sl   09:26   0:00  \_ unit: router
nginx     6715  0.3  1.9 1178344 37432 ?       S    09:46   0:00  \_ unit: "php72domaincom" application
nginx     6716  0.3  2.8 1175444 53728 ?       S    09:46   0:00  \_ unit: "php71domaincom" application
nginx     6729  0.4  2.8 1174400 53304 ?       S    09:46   0:00  \_ unit: "php70domaincom" application
nginx     6730  0.6  2.3 1062704 43740 ?       S    09:46   0:00  \_ unit: "php56domaincom" application
```


# individual json config files

Contents of json config files individual saved at `/root/tools/unitconfigs`

## 5.6.31

/root/tools/unitconfigs/php5631start.json

```
{
     "listeners": {
         "*:8300": {
             "application": "php56domaincom"
         }
     },
     "applications": {
         "php56domaincom": {
             "type": "php 5.6.31",
              "workers": 20,
              "root": "/home/nginx/domains/domain.com/public",
              "user": "nginx",
              "group": "nginx",
              "index": "index.php"
         }
     }
}
```

## 7.0.24

/root/tools/unitconfigs/php7024start.json

```
{
     "listeners": {
         "*:8400": {
             "application": "php70domaincom"
         }
     },
     "applications": {
         "php70domaincom": {
             "type": "php 7.0.24",
              "workers": 20,
              "root": "/home/nginx/domains/domain.com/public",
              "user": "nginx",
              "group": "nginx",
              "index": "index.php"
         }
     }
}
```

## 7.1.10

/root/tools/unitconfigs/php7110start.json

```
{
     "listeners": {
         "*:8500": {
             "application": "php71domaincom"
         }
     },
     "applications": {
         "php71domaincom": {
             "type": "php 7.1.10",
              "workers": 20,
              "root": "/home/nginx/domains/domain.com/public",
              "user": "nginx",
              "group": "nginx",
              "index": "index.php"
         }
     }
}
```

## 7.2.0

/root/tools/unitconfigs/php720start.json

```
{
     "listeners": {
         "*:8600": {
             "application": "php72domaincom"
         }
     },
     "applications": {
         "php72domaincom": {
             "type": "php 7.2.0",
              "workers": 20,
              "root": "/home/nginx/domains/domain.com/public",
              "user": "nginx",
              "group": "nginx",
              "index": "index.php"
         }
     }
}
```