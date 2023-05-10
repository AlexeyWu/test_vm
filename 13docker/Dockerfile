FROM nginx:1.24.0-alpine
LABEL docker install nginx
RUN apk update
# Замена дефолтной конфигурации nginx
COPY default.conf /etc/nginx/conf.d/
# Запуск nginx не в режиме демона, чтоб не было Exit(0)
COPY 1/* /app/1/
COPY 2/* /app/2/
VOLUME /var/log/
VOLUME /app
CMD ["nginx", "-g", "daemon off;"]
EXPOSE 80
EXPOSE 3000

