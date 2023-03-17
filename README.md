_[**Ссылка на репозиторий GitHub**](https://github.com/AlexeyWu/test_vm "Ссылка на репозиторий") в котором находятся файлы указанные в последующих пунктах._


[_Vagrantfile_](https://github.com/AlexeyWu/test_vm/blob/main/packer/Vagrantfile "Vagranfile"), который будет разворачивать виртуальную машину используя vagrant box,_ 
_который вы загрузили Vagrant Cloud._ 


<center>
              **Документация по каждому заданию:**
</center>
=====================[**№1**](https://github.com/AlexeyWu/test_vm)===========================
<br>
<center>
                 *** С чего начинается Linux ***
</center>
Репозиторий [**Vagrant-стенд для обновления ядра и создания образа системы**](https://github.com/AlexeyWu/test_vm)

С помощью нашего стенда, создали образ системы на основе образа Ubuntu при помощи Packer

**Конфигурационные файлы для Packer лежат в [репозитории](https://github.com/AlexeyWu/test_vm):**

**[_Kikstarter config_](https://github.com/AlexeyWu/test_vm/blob/main/packer/http/ks.cfg "ks.cfg - Kikstarter config")**  
**[_Папка со скриптами_](https://github.com/AlexeyWu/test_vm/tree/main/packer/scripts "Папка со скриптами") участвующие в настроке VM**

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
=====================[**№2**](https://github.com/AlexeyWu/test_vm/tree/main/02raid)===========================
<br>
<center>
                      ***Дисковая подсистема	***
</center>
Репозиторий [**Дисковая подсистема: работа с _mdadm_**](https://github.com/AlexeyWu/test_vm/tree/main/02raid)

С помощью [_Vagranfile_](https://github.com/AlexeyWu/test_vm/blob/main/02raid/Vagrantfile) запустили наш стенд в котором добавили дисков для будущего RAID 6

С помощью [_Script_](https://github.com/AlexeyWu/test_vm/blob/main/02raid/raid.sh) файла: 

• собрали RAID 6<br>
• создали GPT раздел, 5 партиций с ext4 и смонтировали их<br> 
• прописали собранный рейд в конф, чтобы рейд собиралсā при загрузке

=====================[**№3**](https://github.com/AlexeyWu/test_vm/tree/main/03lvm1)===========================
<br>
<center>
***Файловые системы и LVM***
</center>
Репозиторий [**Файловые системы и LVM**](https://github.com/AlexeyWu/test_vm/tree/main/02raid)

С помощью [_Vagranfile_](https://github.com/AlexeyWu/test_vm/blob/main/03lvm1/Vagrantfile) запустили наш стенд на имеющемся образе (centos/7 1804.2) в котором проработали:

уменьшили том / до 8G<br>
выделили том под /home<br>
выделить том под /var (/var - сделали в mirror)<br>
для /home - сделать том для снэпшотов<br>
прописали монтирование в fstab (попробовать с разными опциями и разными файловыми системами)<br>
Провели работу со снапшотами:<br>
сгенерировали файлы в /home<br>
сняли снэпшот<br>
удалили часть файлов<br>
восстановились со снэпшота<br>
залоггировали работу утилитой script, скриншотами и т.п.<br>

=====================[**№4**](https://github.com/AlexeyWu/test_vm/tree/main/zfs)===========================
<br>
<center>
***ZFS***
</center>
Репозиторий [**Файловые системы и LVM_**](https://github.com/AlexeyWu/test_vm/tree/main/zfs)
установить и настроить ZFS
