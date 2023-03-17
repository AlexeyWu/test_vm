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


<h2 align="center">#4 <a href="https://github.com/AlexeyWu/test_vm/tree/main/zfs" target="_blank">ZFS</a></h2>

Репозиторий [ZFS](https://github.com/AlexeyWu/test_vm/tree/main/zfs)

установить и настроить ZFS
