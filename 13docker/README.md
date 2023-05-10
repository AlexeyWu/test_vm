# Docker

- _Dockerfile_ - Файл конфигурации создаваемого образа.
- _default.conf_ - файл с настройками NGINX
- [_1_](https://github.com/AlexeyWu/test_vm/tree/main/13docker/1) - папка со статической страницей отвечающей по порту 80 (файл index.html)
- [_2_](https://github.com/AlexeyWu/test_vm/tree/main/13docker/2) - папка со статической страницей отвечающей
 по порту 3000 (файл index.html)

## создание образа с именем _nginx_ и tag - _v1_

```bash
docker build --tag nginx:v1 .
```

## создание контейнера из созданного образа с прбросом требуемых портов на localhost


```bash
docker run -d --name nginx -p 80:80 -p 3000:3000 nginx:v1
```

## проверка работы осуществляется вводом команд на хосте и выводом нашей статической страницы

```bash
curl localhost:80

PORT 80
```

и

```bash
curl localhost:3000

PORT 3000
```
