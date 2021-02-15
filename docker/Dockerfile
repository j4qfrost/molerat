FROM google/dart:2.8.4

WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD . /app
RUN pub get --offline

RUN pub global activate aqueduct
ENTRYPOINT ["/usr/bin/sh", "docker/entrypoint.sh"]
# ENTRYPOINT ["/usr/bin/dart", "bin/main.dart"]