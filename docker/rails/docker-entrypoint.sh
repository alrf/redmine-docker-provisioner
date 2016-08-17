#!/bin/bash

set -e

REDMINE_SRC='/home/redmine/src'
chown -R redmine.redmine $REDMINE_SRC


if [ ! -f /home/redmine/bootstrapped ]
then

su - redmine <<'EOF'
cd $REDMINE_SRC
bundle install --without development test rmagick
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data
touch /home/redmine/bootstrapped
EOF

fi


if [ ! -f $REDMINE_SRC/config/initializers/secret_token.rb ]
then

su - redmine <<'EOF'
cd $REDMINE_SRC
bundle exec rake generate_secret_token
EOF

fi


su - redmine <<'EOF'
cd $REDMINE_SRC
RAILS_ENV=production rails s -b 0.0.0.0
EOF
