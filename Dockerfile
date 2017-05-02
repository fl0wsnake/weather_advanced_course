FROM elixir:1.4.2
RUN mkdir /app
WORKDIR /app
RUN apt-get update
RUN wget -qO- https://deb.nodesource.com/setup_7.x | bash - && apt-get install -y nodejs
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez --force
EXPOSE 4000