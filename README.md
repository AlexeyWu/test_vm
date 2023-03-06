1. Ссылка на репозиторий GitHub в котором находятся файлы указанные в последующих пунктах.
https://github.com/AlexeyWu/test_vm
2. Vagrantfile, который будет разворачивать виртуальную машину используя vagrant box,
   который вы загрузили Vagrant Cloud.
https://github.com/AlexeyWu/test_vm/blob/main/packer/Vagrantfile

3. Документация по каждому заданию:

=====================ЗАДАНИЕ №1===========================

Vagrant-стенд для обновления ядра и создания образа системы

С помощью нашего стенда, создали образ системы на основе образа Ubuntu при помощи Packer

Конфигурационные файлы для Packer лежат в репозитории:
Kikstarter config
https://github.com/AlexeyWu/test_vm/blob/main/packer/http/ks.cfg
Скрипты участвующие в настроке VM
https://github.com/AlexeyWu/test_vm/tree/main/packer/scripts


Vagrantfile для скачивания подготовленного образа и запуска VM в VirtualBox:
https://github.com/AlexeyWu/test_vm/blob/main/packer/Vagrantfile


Ссылка на сам образ в Vagrant Cloud:
        https://app.vagrantup.com/saint1418/boxes/centos8-kernel5

Code скачивания образа на основе собранного выше Packer'ом для вставки в свой Vagrantfile:

Vagrant.configure("2") do |config|

  config.vm.box = "saint1418/centos8-kernel5"

  config.vm.box_version = "1.0"
    
end

===========================================================+