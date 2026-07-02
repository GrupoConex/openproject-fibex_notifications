FROM openproject/openproject:15.4.2

COPY . /app/plugins/fibex_notifications/

RUN echo 'gem "openproject-fibex_notifications", path: "plugins/fibex_notifications"' >> /app/Gemfile.plugins && \
    cd /app && \
    bundle install --quiet
