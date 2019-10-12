FROM ruby:2.5-stretch
WORKDIR /code
ENV RAILS_ENV=production
COPY Gemfile .
RUN bundle install
COPY . .
CMD [ "bundle" "exec" "rails" "server" "-b" "0" ]

