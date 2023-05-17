alias pa='php artisan'
alias pamfs='pa migrate:fresh --seed'
alias pamfspi='pamfs && pa passport:install'

# Create and run a new Laravel app
function laravel_new() {
  laravel_version=""
  php_version="php"
  if [ $# -eq 0 ]; then
    echo "👀 Please enter Laravel app name (default: 'app-x'):"
    read -r name

    if [ -z "$name" ]; then
      name="app-$RANDOM"
    fi

    echo "👀 Please enter Laravel version (default: 'latest'):"
    read -r laravel_version

    echo "👀 Please enter PHP container to run the app on (default: 'php'):"
    read -r version

    if [ -n "$version" ]; then
      php_version=$version
    fi
  else
    if [ -n "$1" ]; then
      name=$1
    fi

    if [ -n "$2" ]; then
      laravel_version=$2
    fi

    if [ -n "$3" ]; then
      php_version=$3
    fi
  fi

  version=""
  if [ -n "$laravel_version" ]; then
    version=":^$laravel_version"

    # check if the version does not have a period
    if echo "$laravel_version" | grep -qv "\."; then
      version+=".0"
    fi
  fi

  cd /shared/httpd || stop_function

  echo_success "\033[1mNow creating your awesome Laravel app! 🔥🔥🔥"

  mkdir "$name"

  cd "$name" || stop_function

  composer create-project "laravel/laravel$version" "$name"

  # symlink and add devilbox config
  symlink "$name" "$name"
  if [ -n "$php_version" ]; then
    php_change "$name" "$php_version"
  else
    php_default "$name"
  fi

  cd "$name" || stop_function

  env=".env"
  # run migrate:fresh --seed if .env exists
  if [ -f $env ]; then
    replace_env_variables "$name"
    pa migrate --seed 2>/dev/null
  fi

  welcome_to_new_app_message "$name"
}

# Clone and run a Laravel app
function laravel_clone() {
  url=""
  php_version="php"
  branch="develop"
  if [ $# -eq 0 ]; then
    echo "👀 Please enter Git URL of your Laravel app:"
    read -r url

    if [ -z "$url" ]; then
      echo_error "You provided an empty Git URL."
      stop_function
    fi

    echo "👀 Please enter branch name to checkout at (default: 'develop'):"
    read -r b

    if [ -n "$b" ]; then
      branch="$b"
    fi

    echo "👀 Please enter app name (default: 'app-x'):"
    read -r name

    if [ -z "$name" ]; then
      name="app-$RANDOM"
    fi

    echo "👀 Please enter PHP container where the app should run (default: 'php'):"
    read -r version

    if [ -n "$version" ]; then
      php_version=$version
    fi
  else
    if [ -n "$1" ]; then
      url=$1
    fi

    if [ -n "$2" ]; then
      branch=$2
    fi

    if [ -n "$3" ]; then
      name=$3
    fi

    if [ -n "$4" ]; then
      php_version=$4
    fi
  fi

  cd /shared/httpd || stop_function

  echo_success "\033[1mNow cloning your awesome Laravel app! 🔥🔥🔥"

  mkdir "$name"

  cd "$name" || stop_function

  git clone "$url" "$name"
  git checkout "$branch" 2>/dev/null

  # symlink and add devilbox config
  symlink "$name" "$name"
  if [ -n "$php_version" ]; then
    php_change "$name" "$php_version"
  else
    php_default "$name"
  fi

  cd "$name" || stop_function

  # copy .env.example to .env
  env=".env"
  if [ ! -f $env ]; then
      cp .env.example "$env" 2>/dev/null
  fi

  # run migrate:fresh --seed if .env exists
  if [ -f $env ]; then
    replace_env_variables "$name"
    pa migrate --seed 2>/dev/null
  fi

  # install dependencies
  project_install

  welcome_to_new_app_message "$name"
}

# Replace DB_HOST on .env with Devilbox's DB URL
function replace_db_host() {
  text_replace "DB_HOST=127.0.0.1" "DB_HOST=172.16.238.12" .env 2>/dev/null
}

# Replace DB_DATABASE on .env with vhost name
function replace_db_name() {
  if [ -n "$1" ]; then
    app=$1
    app=${app//-/_}
    text_replace "DB_DATABASE=laravel" "DB_DATABASE=$app" .env 2>/dev/null
  fi
}

# Replace REDIS_HOST on .env with Devilbox's DB URL
function replace_redis_host() {
  text_replace "REDIS_HOST=127.0.0.1" "REDIS_HOST=172.16.238.14" .env 2>/dev/null
}

# Replace all necessary env variables
function replace_env_variables() {
  if [ -n "$1" ]; then
    replace_db_name "$1"
  fi

  replace_db_host
  replace_redis_host
}
