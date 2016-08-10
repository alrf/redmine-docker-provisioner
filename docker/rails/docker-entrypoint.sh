#!/bin/bash

set -e

chown -R redmine.redmine /home/redmine/src


if [ ! -f /home/redmine/bootstrapped ]
then

su - redmine <<'EOF'
cd /home/redmine/src
bundle exec rake generate_secret_token
bundle install --without development test rmagick
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data
touch /home/redmine/bootstrapped
RAILS_ENV=production rails s -b 0.0.0.0
EOF

else

su - redmine <<'EOF'
cd /home/redmine/src
bundle exec rake generate_secret_token
RAILS_ENV=production rails s -b 0.0.0.0
EOF

fi
