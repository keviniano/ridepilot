FROM ruby:2.2

RUN apt-get update -qq && apt-get install -y build-essential

# for postgres
RUN apt-get install -y libpq-dev

# for nokogiri
RUN apt-get install -y libxml2-dev libxslt1-dev

# for a JS runtime
RUN apt-get install -y nodejs

# Define the working directory
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# Get the Gemfiles
COPY Gemfile $APP_HOME/Gemfile
COPY Gemfile.lock $APP_HOME/Gemfile.lock

# Install all the gems
RUN gem install bundler && bundle install

# Copy the main application
COPY . $APP_HOME

# Expose port 3000 to the Docker host, so we can access it
# from the outside.
EXPOSE 3000

# Configure an entry point, so we don't need to specify
# "bundle exec" for each of our commands.
ENTRYPOINT ["bundle", "exec"]

# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["rails", "server", "-b", "0.0.0.0"]
