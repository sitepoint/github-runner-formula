{%- from "github-runner/map.jinja" import github_runner_settings with context %}

Create ghrunner user:
  user.present:
    - name: ghrunner
    - fullname: GitHub Runner
    - home: {{ github_runner_settings.install_dir }}
    - createhome: False
    - system: True
{%- if github_runner_settings.kernel == "Linux" %}
    - usergroup: True
{%- endif %}

"GitHub Runner Software":
  file.directory:
    - name: {{ github_runner_settings.install_dir }}
    - user: ghrunner
    - group: ghrunner
    - mode: '0750'
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: Create ghrunner user
  archive.extracted:
    - name: {{ github_runner_settings.install_dir }}
    - source: {{ github_runner_settings.package_url }}
{%- if github_runner_settings.package_hash %}
    - source_hash: sha256={{ github_runner_settings.package_hash }}
{%- endif %}
    - user: ghrunner
    - group: ghrunner
    - require:
      - file: "GitHub Runner Software"
  cmd.run:
    - name: >-
        {{ github_runner_settings.install_dir }}/config.{{
          github_runner_settings.script_suffix
        }}
        --unattended --url {{ github_runner_settings.repo_url }}
        --token {{ github_runner_settings.repo_token }}
        --lables {{ ','.join(github_runner_settings.labels) }}
{%- if "runnergroup" in github_runner_settings %}
        --runnergroup {{ github_runner_settings.runnergroup }}
{%- endif %}
    - runas: ghrunner
    - cwd: {{ github_runner_settings.install_dir }}
    - require:
      - archive: "GitHub Runner Software"
    - creates: >-
        {{ github_runner_settings.install_dir }}/svc.{{
          github_runner_settings.script_suffix
        }}

"GitHub Runner Service":
  cmd.run:
    - name: >-
        {{ github_runner_settings.install_dir }}/svc.{{
          github_runner_settings.script_suffix
        }} install
    - creates: {{ github_runner_settings.install_dir }}/.service
    - require:
      - cmd: "GitHub Runner Software"
  service.runner:
    - name: {{
        salt['cmd.run'](
          "cat '" ~ github_runner_settings.install_dir ~ "/.service'"
        )
      }}
    - enable: true
    - require:
      - cmd: "GitHub Runner Service"
