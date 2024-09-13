# Generate ssh key pair
resource "tls_private_key" "mykey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# save the private key to a local file for ssh access   
resource "local_file" "private_key" {
  content  = tls_private_key.mykey.private_key_pem
  filename = "./tools/private_key.pem"
  file_permission = "0600"
}