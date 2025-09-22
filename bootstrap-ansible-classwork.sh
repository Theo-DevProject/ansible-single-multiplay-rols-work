# bootstrap-ansible-classwork.sh
# Run from the ROOT of your repo (pwd should show your repo name)
set -euo pipefail
BASE="$PWD"

echo "[*] Creating Ansible classwork files in: $BASE"

# ---------- roles directories ----------
mkdir -p angular/{files,tasks}
mkdir -p apache/{defaults,files,handlers,meta,tasks,templates,vars}
mkdir -p html/{files,tasks}
mkdir -p php/{tasks}

# ---------- helper files ----------
cat <<'EOF' > README.md
ansible single/multi-play + roles (apache, html, php, angular)

How to run (after editing hosts.ini or using -i with your own inventory):
  ansible all -m ping
  ansible-playbook 01-single-play.yml
  ansible-playbook 02-multi-play.yml
  ansible-playbook 03-httpd.yml
  ansible-playbook 04-ecomm.yml
  ansible-playbook 05-food.yml
  ansible-playbook 06-maintenance.yml
  ansible-playbook 07-ubuntu.yml
  ansible-playbook 08-multi-platform.yml
  ansible-playbook 09-static.yml
  ansible-playbook 10-dynamic.yml
  ansible-playbook 11-vars.yml
  ansible-playbook 12-html-app.yml
  ansible-playbook 13-php-app.yml
  ansible-playbook 14-angular-app.yml
EOF

cat <<'EOF' > hosts.ini
[g1]
# amzn1 ansible_host=YOUR_AMAZON_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/YOUR_KEY.pem

[g2]
# ubt1 ansible_host=YOUR_UBUNTU_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/YOUR_KEY.pem
EOF

cat <<'EOF' > Maintenance.html
<!doctype html><html><head><meta charset="utf-8"><title>Maintenance</title></head>
<body><h1>We’ll be back soon</h1><p>This site is under maintenance. Please check again later.</p></body></html>
EOF

cat <<'EOF' > static.html
<!doctype html><html><head><meta charset="utf-8"><title>Static</title></head>
<body><h1>Static page</h1><p>Deployed by Ansible.</p></body></html>
EOF

cat <<'EOF' > dynamic.j2
<!doctype html>
<html>
<head><meta charset="utf-8"><title>{{ site_title }}</title></head>
<body>
  <h1>{{ site_title }}</h1>
  <ul>
    <li>Host: {{ inventory_hostname }}</li>
    <li>IP: {{ ansible_default_ipv4.address if ansible_default_ipv4 is defined }}</li>
    <li>Distro: {{ ansible_distribution }} {{ ansible_distribution_version }}</li>
    <li>Time: {{ ansible_date_time.iso8601 }}</li>
  </ul>
</body>
</html>
EOF

# ---------- PLAYBOOKS (01–14) ----------
cat <<'EOF' > 01-single-play.yml
---
- name: Single play – ping all
  hosts: all
  gather_facts: yes
  tasks:
    - name: Ping hosts
      ansible.builtin.ping:
    - name: Print distribution
      ansible.builtin.debug:
        msg: "This is {{ ansible_distribution }} {{ ansible_distribution_version }}"
EOF

cat <<'EOF' > 02-multi-play.yml
---
- name: Hello g1
  hosts: g1
  gather_facts: no
  tasks:
    - ansible.builtin.debug: msg="Hello g1"
    - ansible.builtin.debug: msg="g1 reached"

- name: Hello g2
  hosts: g2
  gather_facts: no
  tasks:
    - ansible.builtin.debug: msg="Hello g2"
    - ansible.builtin.debug: msg="g2 reached"
EOF

cat <<'EOF' > 03-httpd.yml
---
- name: Install & start web server per OS
  hosts: all
  become: true
  tasks:
    - name: Install httpd (Amazon/RHEL/CentOS)
      ansible.builtin.yum:
        name: httpd
        state: present
      when: ansible_distribution == "Amazon" or ansible_facts['os_family'] == "RedHat"

    - name: Install apache2 (Debian/Ubuntu)
      ansible.builtin.apt:
        name: apache2
        state: present
        update_cache: yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Start & enable httpd
      ansible.builtin.service:
        name: httpd
        state: started
        enabled: yes
      when: ansible_distribution == "Amazon" or ansible_facts['os_family'] == "RedHat"

    - name: Start & enable apache2
      ansible.builtin.service:
        name: apache2
        state: started
        enabled: yes
      when: ansible_facts['os_family'] == "Debian"
EOF

cat <<'EOF' > 04-ecomm.yml
---
- name: E-comm demo – create dirs & user
  hosts: all
  become: true
  vars:
    app_user: ecomm
    app_dirs: [/opt/ecomm, /opt/ecomm/bin, /opt/ecomm/data]
  tasks:
    - name: Ensure user exists
      ansible.builtin.user:
        name: "{{ app_user }}"
        shell: /bin/bash
    - name: Create directories
      ansible.builtin.file:
        path: "{{ item }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'
      loop: "{{ app_dirs }}"
EOF

cat <<'EOF' > 05-food.yml
---
- name: Install packages by OS family
  hosts: all
  become: true
  vars:
    rhel_packages: [git, curl, tree]
    deb_packages: [git, curl, tree]
  tasks:
    - name: RHEL family packages
      ansible.builtin.yum:
        name: "{{ rhel_packages }}"
        state: present
      when: ansible_distribution == "Amazon" or ansible_facts['os_family'] == "RedHat"
    - name: Debian family packages
      ansible.builtin.apt:
        name: "{{ deb_packages }}"
        state: present
        update_cache: yes
      when: ansible_facts['os_family'] == "Debian"
EOF

cat <<'EOF' > 06-maintenance.yml
---
- name: Put site in maintenance mode
  hosts: all
  become: true
  vars: { docroot: /var/www/html }
  tasks:
    - import_playbook: 03-httpd.yml
    - name: Copy maintenance page
      ansible.builtin.copy:
        src: ./Maintenance.html
        dest: "{{ docroot }}/index.html"
        mode: '0644'
EOF

cat <<'EOF' > 07-ubuntu.yml
---
- name: Ubuntu-only maintenance ops
  hosts: all
  become: true
  tasks:
    - name: apt update (Debian family)
      ansible.builtin.apt:
        update_cache: yes
      when: ansible_facts['os_family'] == "Debian"
    - name: Print distro/version
      ansible.builtin.debug:
        msg: "Running on {{ ansible_distribution }} {{ ansible_distribution_version }}"
EOF

cat <<'EOF' > 08-multi-platform.yml
---
- name: Multi-platform web install (class spec)
  hosts: all
  become: true
  tasks:
    - name: Install httpd
      ansible.builtin.yum:
        name: httpd
        state: present
      when: ansible_distribution == "Amazon" or ansible_facts['os_family'] == "RedHat"
    - name: start httpd
      ansible.builtin.service:
        name: httpd
        state: started
      when: ansible_distribution == "Amazon" or ansible_facts['os_family'] == "RedHat"
    - name: enable httpd
      ansible.builtin.service:
        name: httpd
        enabled: yes
      when: ansible_distribution == "Amazon" or ansible_facts['os_family'] == "RedHat"

    - name: Install apache2
      ansible.builtin.apt:
        name: apache2
        state: present
        update_cache: yes
      when: ansible_facts['os_family'] == "Debian"
    - name: start apache2
      ansible.builtin.service:
        name: apache2
        state: started
      when: ansible_facts['os_family'] == "Debian"
    - name: enable apache2
      ansible.builtin.service:
        name: apache2
        enabled: yes
      when: ansible_facts['os_family'] == "Debian"
EOF

cat <<'EOF' > 09-static.yml
---
- name: Deploy static page
  hosts: all
  become: true
  vars: { docroot: /var/www/html }
  tasks:
    - import_playbook: 03-httpd.yml
    - name: Copy static page
      ansible.builtin.copy:
        src: ./static.html
        dest: "{{ docroot }}/index.html"
        mode: '0644'
EOF

cat <<'EOF' > 10-dynamic.yml
---
- name: Deploy dynamic templated page
  hosts: all
  become: true
  vars:
    docroot: /var/www/html
    site_title: "Ansible Dynamic Site"
  tasks:
    - import_playbook: 03-httpd.yml
    - name: Render template
      ansible.builtin.template:
        src: ./dynamic.j2
        dest: "{{ docroot }}/index.html"
        mode: '0644'
EOF

cat <<'EOF' > 11-vars.yml
---
- name: Variables & loops demo
  hosts: all
  become: true
  vars:
    base_dir: /opt/demo
    files: [app.cfg, db.cfg, web.cfg]
  tasks:
    - name: Create base dir
      ansible.builtin.file:
        path: "{{ base_dir }}"
        state: directory
        mode: '0755'
    - name: Create config files
      ansible.builtin.copy:
        dest: "{{ base_dir }}/{{ item }}"
        content: "# created {{ item }} on {{ inventory_hostname }}"
        mode: '0644'
      loop: "{{ files }}"
EOF

cat <<'EOF' > 12-html-app.yml
---
- name: Deploy simple HTML app via roles
  hosts: all
  become: true
  roles:
    - role: apache
    - role: html
EOF

cat <<'EOF' > 13-php-app.yml
---
- name: Deploy PHP app via roles
  hosts: all
  become: true
  roles:
    - role: apache
    - role: php
EOF

cat <<'EOF' > 14-angular-app.yml
---
- name: Deploy Angular-style static app via roles
  hosts: all
  become: true
  roles:
    - role: apache
    - role: angular
EOF

# ---------- ROLE: apache ----------
cat <<'EOF' > apache/defaults/main.yml
---
apache_docroot: /var/www/html
apache_pkg: "{{ 'httpd' if (ansible_distribution == 'Amazon' or ansible_facts['os_family'] == 'RedHat') else 'apache2' }}"
apache_service: "{{ 'httpd' if (ansible_distribution == 'Amazon' or ansible_facts['os_family'] == 'RedHat') else 'apache2' }}"
EOF

cat <<'EOF' > apache/files/index.html
<!doctype html><html><body><h1>Apache Role</h1></body></html>
EOF

cat <<'EOF' > apache/handlers/main.yml
---
- name: restart apache
  ansible.builtin.service:
    name: "{{ apache_service }}"
    state: restarted
EOF

cat <<'EOF' > apache/meta/main.yml
---
galaxy_info:
  author: class
  description: Minimal Apache install/config role
  license: MIT
dependencies: []
EOF

cat <<'EOF' > apache/tasks/main.yml
---
- import_tasks: install.yml
- import_tasks: config.yml
- import_tasks: service.yml
EOF

cat <<'EOF' > apache/tasks/install.yml
---
- name: Install package
  ansible.builtin.package:
    name: "{{ apache_pkg }}"
    state: present
- name: Ensure docroot exists
  ansible.builtin.file:
    path: "{{ apache_docroot }}"
    state: directory
    mode: '0755'
EOF

cat <<'EOF' > apache/tasks/config.yml
---
- name: Drop index file
  ansible.builtin.copy:
    src: index.html
    dest: "{{ apache_docroot }}/index.html"
    mode: '0644'

- name: Render vhost template (RHEL family)
  ansible.builtin.template:
    src: vhost.j2
    dest: /etc/httpd/conf.d/00-default.conf
  when: apache_service == 'httpd'
  notify: restart apache
EOF

cat <<'EOF' > apache/tasks/service.yml
---
- name: Enable & start service
  ansible.builtin.service:
    name: "{{ apache_service }}"
    state: started
    enabled: yes
EOF

cat <<'EOF' > apache/templates/vhost.j2
<VirtualHost *:80>
    ServerName {{ inventory_hostname }}
    DocumentRoot {{ apache_docroot }}
    <Directory "{{ apache_docroot }}">
        AllowOverride None
        Require all granted
    </Directory>
    ErrorLog logs/error_log
    CustomLog logs/access_log combined
</VirtualHost>
EOF

cat <<'EOF' > apache/vars/main.yml
---
vhost_servername: "{{ inventory_hostname }}"
EOF

# ---------- ROLE: html ----------
cat <<'EOF' > html/tasks/main.yml
---
- name: Deploy static HTML app
  ansible.builtin.copy:
    src: "{{ role_path }}/files/index.html"
    dest: "/var/www/html/index.html"
    mode: '0644'
EOF

cat <<'EOF' > html/files/index.html
<!doctype html><html><body><h1>HTML App</h1><p>Served by Apache.</p></body></html>
EOF

# ---------- ROLE: php ----------
cat <<'EOF' > php/tasks/main.yml
---
- name: Install PHP on Debian/Ubuntu
  ansible.builtin.apt:
    name: [php, libapache2-mod-php]
    state: present
    update_cache: yes
  when: ansible_facts['os_family'] == 'Debian'

- name: Install PHP on RedHat/Amazon
  ansible.builtin.yum:
    name: [php, php-cli]
    state: present
  when: ansible_distribution == 'Amazon' or ansible_facts['os_family'] == 'RedHat'

- name: Deploy PHP index
  ansible.builtin.copy:
    dest: /var/www/html/index.php
    mode: '0644'
    content: |
      <?php phpinfo(); ?>

- name: Ensure Apache uses index.php
  ansible.builtin.lineinfile:
    path: "{{ (ansible_facts['os_family'] == 'Debian') | ternary('/etc/apache2/mods-enabled/dir.conf','/etc/httpd/conf/httpd.conf') }}"
    regexp: '^DirectoryIndex'
    line: "DirectoryIndex index.php index.html"
  notify: restart apache
EOF

# ---------- ROLE: angular ----------
cat <<'EOF' > angular/tasks/main.yml
---
- name: Create Angular app directory
  ansible.builtin.file:
    path: /var/www/html/angular
    state: directory
    mode: '0755'
- name: Deploy Angular-like index
  ansible.builtin.copy:
    src: "{{ role_path }}/files/index.html"
    dest: /var/www/html/angular/index.html
    mode: '0644'
EOF

cat <<'EOF' > angular/files/index.html
<!doctype html>
<html>
<head><meta charset="utf-8"><title>Angular App</title></head>
<body><app-root>Angular app placeholder (static).</app-root></body>
</html>
EOF

echo "[*] Done creating files."