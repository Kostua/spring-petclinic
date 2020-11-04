#---------------------------------------------------------------------------------------------------------------------
# Provision the server using remote-exec
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "ansible_provisioner" {
  triggers = {
    public_ip = var.trigger_public_ip 
  }

  connection {
    type        = "ssh"
    host        = var.public_ip 
    user        = var.username
    private_key = var.private_key_pem
  }

  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    #  Install Python for Ansible
    inline = [
      "sudo yum install -y python3 pip3 docker-py libselinux-python"
    ]
  }

  provisioner "local-exec" {
    command = "ansible-galaxy collection install community.general && ansible-galaxy role install -r requirements.yml && ansible-playbook -u '${var.username}' -i '${var.public_ip},' -T 300 provision.yml" 
  }
}
