#!/usr/bin/env bats

BASE_USER=alpine
DOCKER_VERSION=1.13.0
COMPOSE_VERSION=1.11.1

execute_vagrant_ssh_command() {
    vagrant ssh -c "${*}" -- -n -T
}

@test "We can start the VM with vagrant" {
    vagrant up
}

@test "We can SSH inside the VM with vagrant" {
    execute_vagrant_ssh_command "echo OK"
}

@test "Default user of the VM is ${BASE_USER}" {
    execute_vagrant_ssh_command "whoami" | grep "${BASE_USER}"
}

@test "Default shell of default user ${BASE_USER} is bash" {
    # Configured User shell
    execute_vagrant_ssh_command 'echo ${SHELL}' | grep '/bin/bash'
    # Effective shell
    execute_vagrant_ssh_command 'echo ${0}' | grep 'bash'
}

@test "We have the passwordless sudoers rights inside the VM" {
    execute_vagrant_ssh_command 'sudo whoami' | grep root
}

@test "SSH does not allow root login" {
    [ "$(execute_vagrant_ssh_command \
        'grep PermitRootLogin /etc/ssh/sshd_config' \
        | grep yes | wc -l )" -eq 0 ]
}

@test "SSH does not use DNS resolution (faster vagrant ssh)" {
    execute_vagrant_ssh_command "grep 'UseDNS no' /etc/ssh/sshd_config"
}

@test "The root filesystem is located on a LVM volume" {
     execute_vagrant_ssh_command 'sudo df -h | grep "/dev/vg0/lv_root" \
        | grep "/$" | wc -l'
}

@test "Swap is enabled" {
    [ $(execute_vagrant_ssh_command "free -m | grep Swap | awk '{print \$2}'") -ge 0 ]
}

@test "Docker Client is in version ${DOCKER_VERSION}" {
    execute_vagrant_ssh_command "docker -v" | grep "${DOCKER_VERSION}"
}

@test "Docker Compose is in version ${COMPOSE_VERSION}" {
    execute_vagrant_ssh_command "docker-compose -v" | grep "${COMPOSE_VERSION}"
}

@test "The default admin user ${BASE_USER} is in the docker group" {
    execute_vagrant_ssh_command "grep docker /etc/group | grep ${BASE_USER}"
}

@test "Docker Engine is started and respond correctly without sudo" {
    execute_vagrant_ssh_command "docker info"
}

@test "We have a customize folder where default user can write inside" {
    execute_vagrant_ssh_command "[ -d /var/customize ] \
        && touch /var/customize/test"
}

@test "We have a shutdown command" {
    execute_vagrant_ssh_command "which shutdown" | grep '/sbin/shutdown'
}

@test "We can restart the machine properly" {
    vagrant reload
}

@test "We can stop properly the machine" {
    vagrant halt
}

@test "We can destroy the vagrant" {
    vagrant destroy -f
}