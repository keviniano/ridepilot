Ridepilot Verson 3
================

The purpose of this project is to implement a Computer Aided Scheduling and Dispatch (CASD) software system to meet the needs of small scale human service transportation agencies. 

Status
-------------
work in progress

- development: check [develop](https://github.com/camsys/ridepilot/tree/develop)

- latest stable: check [master](https://github.com/camsys/ridepilot/tree/master)

- Ridepilot Version 2 branch: check [ridepilot\_v1](https://github.com/camsys/ridepilot/tree/ridepilot_v2)

Dependencies
-------------

This application requires:

- Ruby 2.5
- Rails 5.1
- Postgresql 9.3+
- PostGIS 2.1+
- Imagemagick
- Redis

Set up development environment
-------------

1. Install the required versions of Postgresql, PostGIS, and any other system packages required for your setup

2. Application setup
    - `bundle install`
    - Copy `config/application.example.yml` to `config/application.yml` and update the values.

3. Database setup
    - Copy `config/database.yml.example.pg` to `config/database.yml` and update the values for specific environment (at least __development__ and __test__).

    - `rails db:setup`

4. Testing
    - set up test database if not yet
      - make sure `config/database.yml` has the configurations for __test__ environment
    - update schema and locales
      - `rails db:test:prepare`
    - `rspec`

5. Start application
    - `rails s`

License
-------
  The RidePilot platform source code is released as open-source software under the GNU Affero General Public License v3 (http://www.gnu.org/licenses/agpl-3.0.en.html) license.