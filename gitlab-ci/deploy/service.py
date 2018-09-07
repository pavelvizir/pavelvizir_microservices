#!/usr/bin/env python
''' '''

from flask import Flask, make_response, request
import os


app = Flask(__name__)


@app.route('/create', methods=['POST'])
def create():
    name = request.form['name']
    result=os.popen("cp -rv /srv/server-spawn/files /srv/server-spawn/branch_" + name + " && cd /srv/server-spawn/branch_" + name + " && terraform init && terraform apply -auto-approve -var-file /srv/server-spawn/project_name.tfvars -var 'name=" + name + "' && sleep 60 && ansible-playbook server_prepare.yml --timeout=600 --limit=" + name).read()
    print(result)
    resp = make_response(result, 200)
    resp.headers['X-Something'] = 'A value'
    return resp


@app.route('/destroy', methods=['POST'])
def destroy():
    name = request.form['name']
    result=os.popen("cd /srv/server-spawn/branch_" + name + " && terraform destroy -auto-approve -var-file /srv/server-spawn/project_name.tfvars -var 'name=" + name + "' && rm -rf /srv/server-spawn/branch_" + name).read()
    print(result)
    resp = make_response(result, 200)
    resp.headers['X-Something'] = 'A value'
    return resp


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9999)

