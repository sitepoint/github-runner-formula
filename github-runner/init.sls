{%- from "github-runner/map.jinja" import github_runner_settings with context %}

"GitHub Runner Software":
  file.directory:
    - name: {{ github_runner_settings.install_dir }}
    - makedirs: true
  archive.extracted:
    - name: {{ github_runner_settings.install_dir }}
    - source: {{ github_runner_settings.package_url }}
    - source_hash: sha256={{ github_runner_settings.package_hash }}
    - require:
      - file: "GitHub Runner Software"
  cmd.run:
    - name: {{ github_runner_settings.install_dir }}/config.{{ github_runner_settings.script_suffix }} --unattended --url {{ github_runner_settings.repo_url }} --token ${{ github_runner_settings.repo_token }}
    - require:
      - archive: "GitHub Runner Software"
    - creates: {{ github_runner_settings.install_dir }}/svc.{{ github_runner_settings.script_suffix }}

"GitHub Runner Service":
  service.runner:
    - name: {{ github_runner_settings.service_name }}
    - enable: true
    - require:
      - archive: "GitHub Runner Software"
      - cmd: "GitHub Runner Service"
  cmd.run:
    - name: {{ github_runner_settings.install_dir}}/svc.{{ github_runner_settings.script_suffix }} install
    - require:
      - file: {{ github_runner_settings.install_dir }}/svc.{{ github_runner_settings.script_suffix }}
    - watch:
      - cmd: "GitHub Runner Software"
