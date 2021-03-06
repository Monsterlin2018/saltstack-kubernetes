kube-scan-namespace:
  file.managed:
    - require:
      - file: /srv/kubernetes/manifests/kube-scan
    - name: /srv/kubernetes/manifests/kube-scan/namespace.yaml
    - source: salt://{{ tpldir }}/files/namespace.yaml
    - user: root
    - template: jinja
    - group: root
    - mode: "0644"
    - context:
      tpldir: {{ tpldir }}
  cmd.run:
    - watch:
        - file: /srv/kubernetes/manifests/kube-scan/namespace.yaml
    - runas: root
    - name: |
        kubectl apply -f /srv/kubernetes/manifests/kube-scan/namespace.yaml
    - onlyif: curl --silent 'http://127.0.0.1:8080/version/'