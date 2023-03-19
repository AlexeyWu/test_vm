_[**Ссылка на репозиторий GitHub**](https://github.com/AlexeyWu/test_vm "Ссылка на репозиторий") в котором находятся файлы указанные в последующих пунктах._


[_Vagrantfile_](https://github.com/AlexeyWu/test_vm/blob/main/packer/Vagrantfile "Vagranfile"), который будет разворачивать виртуальную машину используя vagrant box,_ 
_который вы загрузили Vagrant Cloud._ 


<h1 align="center">Документация по каждому заданию:</h1>
<br>
<h2 align="center">#1 <a href="https://github.com/AlexeyWu/test_vm" target="_blank">С чего начинается Linux </a></h2>

Репозиторий [Vagrant-стенд для обновления ядра и создания образа системы](https://github.com/AlexeyWu/test_vm)

С помощью нашего стенда, создали образ системы на основе образа Ubuntu при помощи Packer

**Конфигурационные файлы для Packer [лежат в](https://github.com/AlexeyWu/test_vm/tree/main/packer):**

**[_Kikstarter config_](https://github.com/AlexeyWu/test_vm/blob/main/packer/http/ks.cfg "ks.cfg - Kikstarter config")**  
**[_Папка со скриптами_](https://github.com/AlexeyWu/test_vm/tree/main/packer/scripts "Папка со скриптами")**

**Vagrantfile для скачивания подготовленного образа и запуска VM в VirtualBox:**
[Vagrantfile](https://github.com/AlexeyWu/test_vm/blob/main/packer/Vagrantfile "Vagrantfile")

**Ссылка на сам [_образ_](https://app.vagrantup.com/saint1418/boxes/centos8-kernel5 "образ centos8-kernel5") в Vagrant Cloud:** 


**Code скачивания образа на основе собранного выше *Packer'ом* для вставки в свой *Vagrantfile*:**

```yaml
Vagrant.configure("2") do |config|
    config.vm.box = "saint1418/centos8-kernel5"
    config.vm.box_version = "1.0"
end
```

<br>
<h2 align="center">#2 <a href="https://github.com/AlexeyWu/test_vm/tree/main/02raid" target="_blank">Дисковая подсистема</a></h2>

Репозиторий [Дисковая подсистема\: работа с mdadm](https://github.com/AlexeyWu/test_vm/tree/main/02raid)

С помощью [_Vagranfile_](https://github.com/AlexeyWu/test_vm/blob/main/02raid/Vagrantfile) запустили наш стенд в котором добавили дисков для будущего RAID 6

С помощью [_Script_](https://github.com/AlexeyWu/test_vm/blob/main/02raid/raid.sh) файла: 

* собрали RAID 6
* создали GPT раздел, 5 партиций с ext4 и смонтировали их<br> 
* прописали собранный рейд в конф, чтобы рейд собиралсā при загрузке


<br>
<h2 align="center">#3 <a href="https://github.com/AlexeyWu/test_vm/tree/main/03lvm1" target="_blank">Файловые системы и LVM</a></h2>
<br>

Репозиторий [**Файловые системы и LVM**](https://github.com/AlexeyWu/test_vm/tree/main/03lvm1)

С помощью [_Vagranfile_](https://github.com/AlexeyWu/test_vm/blob/main/03lvm1/Vagrantfile) запустили наш стенд на имеющемся образе (centos/7 1804.2) в котором проработали:

* уменьшили том / до 8G
* выделили том под _/home_
* выделить том под _/var (/var - сделали в mirror)_
* для _/home_ - сделать том для снэпшотов
* прописали монтирование в _fstab_ (попробовать с разными опциями и разными файловыми системами)
* Провели работу со снапшотами:
* сгенерировали файлы в _/home_
* сняли снэпшот
* удалили часть файлов
* восстановились со снэпшота
* залоггировали работу утилитой _script_, _скриншотами и т.п._


<h2 align="center">#4 <a href="https://github.com/AlexeyWu/test_vm/tree/main/04zfs" target="_blank">ZFS</a></h2>

Репозиторий [ZFS](https://github.com/AlexeyWu/test_vm/tree/main/04zfs)
Вывод терминала в [текстовом файле](https://github.com/AlexeyWu/test_vm/blob/main/04zfs/%D0%B2%D1%8B%D0%B2%D0%BE%D0%B4_%D1%82%D0%B5%D1%80%D0%BC%D0%B8%D0%BD%D0%B0%D0%BB%D0%B0.txt)

    Устанавшливаем [Vagrantfile](https://github.com/AlexeyWu/test_vm/tree/main/04zfs/Vagrantfile) vb _centos\7 2004.1_
    С использованием скрипта [test.sh](https://github.com/AlexeyWu/test_vm/blob/main/04zfs/test.sh)

* Определяем алгоритм с наилучшим сжатием
    Исходя из тестов видно что наилучший алгоритм компресси при одинаковом наборе данных у нас _otus3_:

 ```
zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21,6M   330M     21,6M  /otus1
otus2  17,7M   334M     17,6M  /otus2
otus3  10,8M   341M     10,7M  /otus3
otus4  39,1M   313M     39,1M  /otus4

zfs get all | grep compressratio | grep -v refotus1
otus1  compressratio         1.81x                      -
otus2  compressratio         2.22x                      -
otus3  compressratio         3.65x                      -
otus4  compressratio         1.00x                      -

 ```
* Определим настройки pool
    - Скачали и разархивировали архив в домашний каталог
    - Проверили с помощью команды _zpool import -d zpoolexport/_ возможно ли импортировать каталог в _pool_
    - Импортировали данныый пул в нашу ОС с помощью команды: _zpool import -d zpoolexport/ otus_
    - Командами zfs определить настройки:
    ```
    [root@zfs vagrant]# zfs get available otus
    NAME  PROPERTY   VALUE  SOURCE
    otus  available  350M   -
    [root@zfs vagrant]# zfs get readonly otus
    NAME  PROPERTY  VALUE   SOURCE
    otus  readonly  off     default
    [root@zfs vagrant]# zfs get recordsize otus
    NAME  PROPERTY    VALUE    SOURCE
    otus  recordsize  128K     local
    [root@zfs vagrant]# zfs get compression otus
    NAME  PROPERTY     VALUE     SOURCE
    otus  compression  zle       local
    [root@zfs vagrant]# zfs get checksum otus
    NAME  PROPERTY  VALUE      SOURCE
    otus  checksum  sha256     local

    ```
* Првели работу со снапшотом, нашли [сообщения от преподавателя](https://github.com/AlexeyWu/test_vm/blob/main/04zfs/Screenshot%20from%202023-03-19%2019-54-15.png):
    - Это ссылка на_https://github.com/sindresorhus/awesome_

<h2 align="center">#5 <a href="https://github.com/AlexeyWu/test_vm/tree/main/05" target="_blank">Пока нет</a></h2>