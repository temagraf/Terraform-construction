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
