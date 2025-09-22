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
