# -*- coding: utf-8 -*-
# vim: ft=jinja

{#- Get the `tplroot` from `tpldir` #}
{% from tpldir ~ "/map.jinja" import cert_manager with context %}

cert-manager-crds:
  cmd.run:
    - watch:
        - file: /srv/kubernetes/manifests/cert-manager/00-crds.yaml
    - runas: root
    - use_vt: True
    - onlyif: curl --silent 'http://127.0.0.1:8080/healthz/'
    - name: kubectl apply -f /srv/kubernetes/manifests/cert-manager/00-crds.yaml

cert-manager-remove-secret:
  cmd.run:
    - watch:
      - cmd: cert-manager-namespace
    - runas: root
    - use_vt: True
    - onlyif: kubectl -n cert-manager get secret public-dns-secret
    - name: kubectl -n cert-manager delete secret public-dns-secret

cert-manager-create-secret:
  cmd.run:
    - watch:
      - cmd: cert-manager-remove-secret
    - runas: root
    - use_vt: True
    - name: kubectl -n cert-manager create secret generic public-dns-secret --from-literal=secret-access-key="{{ cert_manager.dns.secret }}"

cert-manager:
  cmd.run:
    - runas: root
    - watch:
      - cmd: cert-manager-namespace
      - cmd: cert-manager-fetch-charts
    - cwd: /srv/kubernetes/manifests/cert-manager/cert-manager
    - name: |
        helm upgrade --install cert-manager --namespace cert-manager \
            "./" --wait --timeout 5m

query-cert-manager-required-api:
  http.wait_for_successful_query:
    - name: 'http://127.0.0.1:8080/apis/cert-manager.io'
    - match: APIGroup
    - wait_for: 180
    - request_interval: 5
    - status: 200

cert-manager-clusterissuer:
  cmd.run:
    - require:
      - http: query-cert-manager-required-api
      - cmd: cert-manager-create-secret
    - watch:
        - file: /srv/kubernetes/manifests/cert-manager/clusterissuer.yaml
    - runas: root
    - use_vt: True
    - onlyif: curl --silent 'http://127.0.0.1:8080/apis/cert-manager.io'
    - name: |
        kubectl apply -f /srv/kubernetes/manifests/cert-manager/clusterissuer.yaml