# Домашнее задание "`«Управляющие конструкции в коде Terraform»`"   

---

### Задание 1

1) Изучите проект.
2) Заполните файл personal.auto.tfvars.
3) Инициализируйте проект, выполните код. Он выполнится, даже если доступа к preview нет.

Приложите скриншот входящих правил «Группы безопасности» в ЛК Yandex Cloud или скриншот отказа в предоставлении доступа к preview-версии.

### Выполнения задания 1

Изучил проект, заполнил personal.auto.tfvars, выполнил: 
 ```sh

terraform plan 
terraform apply 

```
 В результате в YC создана группа сеть develop с подсетью develop и группой безопасности example_dynamic:

 ![image.jpg](https://github.com/temagraf/Terraform-construction/blob/main/1.png) 


---

### Задание 2

1) Создайте файл count-vm.tf. Опишите в нём создание двух одинаковых ВМ web-1 и web-2 (не web-0 и web-1) с минимальными параметрами, используя мета-аргумент count loop. Назначьте ВМ созданную в первом задании группу безопасности.(как это сделать узнайте в документации провайдера yandex/compute_instance )
2) Создайте файл for_each-vm.tf. Опишите в нём создание двух ВМ для баз данных с именами "main" и "replica" разных по cpu/ram/disk_volume , используя мета-аргумент for_each loop.
При желании внесите в переменную все возможные параметры. 4. ВМ из пункта 2.1 должны создаваться после создания ВМ из пункта 2.2. 5. Используйте функцию file в local-переменной для считывания ключа ~/.ssh/id_rsa.pub и его последующего использования в блоке metadata, взятому из ДЗ 2. 6. Инициализируйте проект, выполните код.

### Выполнения задания 2

- В файле variables.tf добавил переменные web_vm и backend_vm с дефолтными параметрами для создания ВМ. 
Параметры вынесены в переменные, без хардкода.
- В файле count-vm.tf описал создание двух одинаковых ВМ web-1 и web-2, в файле for_each-vm.tf описал создание main и replica.
- depends_on обозначил, что backend-ВМ создается только после web-ВМ.
- locals.tf считываем открытыю част ключа из файла и составление local-метаданных, которые затем с помощью merge соединяются с metadata из variables ВМ.

Выполняем и видим, что ресурсы созданы.

```sh

terraform plan 
terraform apply 

```

 ![image.jpg](https://github.com/temagraf/Terraform-construction/blob/main/2.png) 

 ![image.jpg](https://github.com/temagraf/Terraform-construction/blob/main/2%2C1.png)

### Задание 3

1) Создайте 3 одинаковых виртуальных диска размером 1 Гб с помощью ресурса yandex_compute_disk и мета-аргумента count в файле disk_vm.tf .
2) Создайте в том же файле одиночную(использовать count или for_each запрещено из-за задания №4) ВМ c именем "storage" . Используйте блок dynamic secondary_disk{..} и мета-аргумент for_each для подключения созданных вами дополнительных дисков.

### Выполнения задания 3

- В файле disk_vm.tf создал ресурс с дисками и ВМ storage.
  
![image.jpg](https://github.com/temagraf/Terraform-construction/blob/main/3.png)

![image.jpg](https://github.com/temagraf/Terraform-construction/blob/main/3.1.png)


### Задание 4

1) В файле ansible.tf создайте inventory-файл для ansible. Используйте функцию tepmplatefile и файл-шаблон для создания ansible inventory-файла из лекции. Готовый код возьмите из демонстрации к лекции demonstration2. Передайте в него в качестве переменных группы виртуальных машин из задания 2.1, 2.2 и 3.2, т. е. 5 ВМ.
2) Инвентарь должен содержать 3 группы и быть динамическим, т. е. обработать как группу из 2-х ВМ, так и 999 ВМ.
3) Добавьте в инвентарь переменную fqdn.

### Выполнения задания 4

ansible.tf

```sh
resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    webservers = yandex_compute_instance.web
    databases  = yandex_compute_instance.backend
    storage    = [yandex_compute_instance.storage]
  })
  filename = "${abspath(path.module)}/hosts.cfg"
}

resource "null_resource" "provision_web" {
  depends_on = [
    yandex_compute_instance.web,
    local_file.inventory
  ]

  provisioner "local-exec" {
    command = "cat ~/.ssh/id_ed25519 | ssh-add -"
  }

  provisioner "local-exec" {
    command     = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -i ${abspath(path.module)}/hosts.cfg ${abspath(path.module)}/playbook.yml"
    on_failure  = continue 
    environment = { ANSIBLE_HOST_KEY_CHECKING = "False" } 
  }
  triggers = {
    always_run        = timestamp()                         
    playbook_src_hash = file("${abspath(path.module)}/playbook.yml") 
    ssh_public_key    = local.ssh-key                           
  }
}
```

Cформировал template inventory.tftpl

```sh
[webservers]

%{~ for i in webservers ~}
${i["name"]}   ansible_host=${i.network_interface[0].nat_ip_address == "" ? i.network_interface[0].ip_address : i.network_interface[0].nat_ip_address}

%{~ endfor ~}

[databases]

%{~ for i in databases ~}
${i["name"]}   ansible_host=${i.network_interface[0].nat_ip_address == "" ? i.network_interface[0].ip_address : i.network_interface[0].nat_ip_address}

%{~ endfor ~}

[storage]

%{~ for i in storage ~}
${i["name"]}   ansible_host=${i.network_interface[0].nat_ip_address == "" ? i.network_interface[0].ip_address : i.network_interface[0].nat_ip_address}

%{~ endfor ~}
```

![image.jpg](https://github.com/temagraf/Terraform-construction/blob/main/4.png)
