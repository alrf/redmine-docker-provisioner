#!/bin/bash

set -e

chown -R redmine.redmine /home/redmine/src


if [ ! -f /home/redmine/bootstrapped ]
then

su - redmine <<'EOF'
cd /home/redmine/src
bundle install --without development test rmagick
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data
touch /home/redmine/bootstrapped
EOF

fi


if [ ! -f /home/redmine/src/config/initializers/secret_token.rb ]
then

su - redmine <<'EOF'
cd /home/redmine/src
bundle exec rake generate_secret_token
EOF

fi


su - redmine <<'EOF'
cd /home/redmine/src
RAILS_ENV=production rails s -b 0.0.0.0
EOF
