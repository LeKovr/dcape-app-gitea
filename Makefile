## Gitea Makefile.
## Used with dcape at ../../
#:

SHELL               = /bin/bash
CFG                ?= .env

# Docker image and version tested for actual dcape release
GITEA_IMAGE0       ?= gitea/gitea
GITEA_VER0         ?= 1.19.3

#- ******************************************************************************
#- Gitea: general config

#- Gitea hostname
GITEA_HOST         ?= git.$(DCAPE_DOMAIN)
#- Gitea ssh server port
#- You should change sshd port and set this to 22
GITEA_SSH_PORT     ?= 10022

#- ------------------------------------------------------------------------------
#- Gitea: internal config

#- Database name and database user name
GITEA_DB_TAG       ?= gitea
#- Database user password
GITEA_DB_PASS      ?= $(shell openssl rand -hex 16; echo)
#- Gitea Docker image
GITEA_IMAGE        ?= $(GITEA_IMAGE0)
#- Gitea Docker image version
GITEA_VER          ?= $(GITEA_VER0)

#- Gitea admin user name
GITEA_ADMIN_NAME   ?= $(DCAPE_ADMIN_USER)
#- Gitea admin user email
GITEA_ADMIN_EMAIL  ?= $(GITEA_ADMIN_NAME)@$(DCAPE_DOMAIN)
#- Gitea admin user password
GITEA_ADMIN_PASS   ?= $(shell openssl rand -hex 16; echo)

#- Gitea mailer enabled
GITEA_MAILER_ENABLED  ?= false
#- Gitea mailer ip
GITEA_MAILER_ADDR     ?=
#- Gitea mailer port
GITEA_MAILER_PORT     ?=
#- Gitea mailer sender email
GITEA_MAILER_FROM     ?=
#- Gitea mailer user
GITEA_MAILER_USER     ?=
#- Gitea mailer password
GITEA_MAILER_PASS     ?=

#- dcape root directory
DCAPE_ROOT         ?= $(DCAPE_ROOT)

NAME               ?= GITEA
DB_INIT_SQL         =

# ------------------------------------------------------------------------------

-include $(CFG)
export

ifdef DCAPE_STACK
include $(DCAPE_ROOT)/Makefile.dcape
else
include $(DCAPE_ROOT)/Makefile.app
endif

# ------------------------------------------------------------------------------

# Init data for $(DCAPE_VAR)/gitea/gitea/conf/app.ini
define INI_GITEA
APP_NAME = Gitea: Git with a cup of tea
RUN_USER = git
RUN_MODE = prod

[server]
SSH_DOMAIN = $(GITEA_HOST)
DOMAIN     = $(GITEA_HOST)
ROOT_URL   = $(DCAPE_SCHEME)://$(GITEA_HOST)/

[database]
DB_TYPE  = postgres
HOST     = db:5432
NAME     = $(GITEA_DB_TAG)
USER     = $(GITEA_DB_TAG)
SSL_MODE = disable
PASSWD   = $(GITEA_DB_PASS)

[service]
REGISTER_EMAIL_CONFIRM            = false
ENABLE_NOTIFY_MAIL                = false
DISABLE_REGISTRATION              = false
ALLOW_ONLY_EXTERNAL_REGISTRATION  = false
ENABLE_CAPTCHA                    = false
REQUIRE_SIGNIN_VIEW               = false
DEFAULT_KEEP_EMAIL_PRIVATE        = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
DEFAULT_ENABLE_TIMETRACKING       = true
NO_REPLY_ADDRESS                  = noreply.$(DCAPE_DOMAIN)

[security]
INSTALL_LOCK   = true

[picture]
DISABLE_GRAVATAR        = false
ENABLE_FEDERATED_AVATAR = true

[openid]
ENABLE_OPENID_SIGNIN = true
ENABLE_OPENID_SIGNUP = true

[session]
PROVIDER = file

[metrics]
ENABLED = true

[webhook]
ALLOWED_HOST_LIST = $(CICD_HOST)

endef
export INI_GITEA

# ------------------------------------------------------------------------------

init: $(DCAPE_VAR)/gitea-app-data $(DCAPE_VAR)/gitea/gitea/conf/app.ini
	@if [[ "$$GITEA_VER0" != "$$GITEA_VER" ]] ; then \
	  echo "Warning: GITEA_VER in dcape ($$GITEA_VER0) differs from yours ($$GITEA_VER)" ; \
	fi
	@if [[ "$$GITEA_IMAGE0" != "$$GITEA_IMAGE" ]] ; then \
	  echo "Warning: GITEA_IMAGE in dcape ($$GITEA_IMAGE0) differs from yours ($$GITEA_IMAGE)" ; \
	fi
	@echo "  URL: $(AUTH_URL)"
	@echo "  SSH port: $(GITEA_SSH_PORT)"

.setup-before-up: db-create

.setup-after-up: setup-users

setup-users:
	$(MAKE) -s vcs-wait
	$(MAKE) -s gitea-admin || true
	$(MAKE) -s token

# Ждем пока развернется gitea
# как вариант - появится таблица user
vcs-wait:
	@echo "Waiting for VCS bootstrap..."
	sleep 10

$(DCAPE_VAR)/gitea/gitea/conf/app.ini: $(DCAPE_VAR)/gitea/gitea/conf
	@echo "$$INI_GITEA" > $@
	@chown 1000:1000 $@

$(DCAPE_VAR)/gitea/gitea/conf:
	@mkdir -p $@
	@chown -R 1000:1000 $@

$(DCAPE_VAR)/gitea-app-data:
	@mkdir -p $@
	@chown 1000:1000 $@


# ------------------------------------------------------------------------------
# setup gitea objects

GITEA_CREATE_TOKEN_URL = $(AUTH_URL)/api/v1/users/$(GITEA_ADMIN_NAME)/tokens

# Create gitea admin user
gitea-admin:
	@echo "*** $@ ***"
	@$(MAKE) -s compose CMD="exec vcs su git -c \
	  'gitea admin user create --admin --username $(GITEA_ADMIN_NAME) --password $(GITEA_ADMIN_PASS) --email $(GITEA_ADMIN_EMAIL)'"

TOKEN_NAME ?= install

# sudo - create org
# write:application - create application

define GITEA_TOKEN_CREATE
{
  "name": "$(TOKEN_NAME)",
  "scopes": ["sudo", "write:application"]
}
endef

token: $(DCAPE_VAR)/oauth2-token

$(DCAPE_VAR)/oauth2-token:
	@echo -n "create token for user $(GITEA_ADMIN_NAME) via $(AUTH_URL)... " ; \
	if resp=$$(echo $$GITEA_TOKEN_CREATE | curl -gsS -X POST -d @- -H "Content-Type: application/json" -u "$(GITEA_ADMIN_NAME):$(GITEA_ADMIN_PASS)" $(GITEA_CREATE_TOKEN_URL)) ; then \
	  if token=$$(echo $$resp | jq -re '.sha1') ; then \
	    echo "Token $$token: Done" ; \
	    echo "define AUTH_TOKEN" > $@ ;\
	    echo "$$token" >> $@ ; \
	    echo "endef" >> $@ ; \
	  else \
	    echo -n "ERROR: " ; \
	    echo $$resp | jq -re '.' ; \
	  fi ; \
	else false ; fi ; \

token-delete:
	echo -n "remove token... " ; \
	if resp=$$(curl -gsS -X DELETE -u "$(GITEA_ADMIN_NAME):$(GITEA_ADMIN_PASS)" $(GITEA_CREATE_TOKEN_URL)/$(TOKEN_NAME)) ; then \
	  if [[ -z $$resp ]] ; then \
	    echo "Done" ; \
	  else \
	    echo -n "ERROR: " ; \
	    echo $$resp | jq -re '.message' ; \
	  fi ; \
	else false ; fi
