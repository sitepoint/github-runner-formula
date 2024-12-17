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
    - unless: test -f /opt/github/actions-runner/run.sh
    - require:
      - file: "GitHub Runner Software"
  cmd.run:
    - name: >-
        {{ github_runner_settings.install_dir }}/config.{{
          github_runner_settings.script_suffix
        }}
        --unattended --url {{ github_runner_settings.repo_url }}
        --token {{ github_runner_settings.repo_token }}
        --labels {{ ','.join(github_runner_settings.labels) }}
{%- if "runnergroup" in github_runner_settings %}
        --runnergroup {{ github_runner_settings.runnergroup }}
{%- endif %}
    - runas: ghrunner
    - cwd: {{ github_runner_settings.install_dir }}
    - require:
      - archive: "GitHub Runner Software"
    - creates:
        - {{ github_runner_settings.install_dir }}/.credentials
        - {{ github_runner_settings.install_dir }}/.runner
        - {{ github_runner_settings.install_dir }}/svc.{{
            github_runner_settings.script_suffix
          }}

# We use cmd instead of file built-in state because that only supports
# octal encoding (issue #32681).
# https://github.com/saltstack/salt/issues/32681
"Secure {{ github_runner_settings.install_dir }}":
  cmd.run:
    - name: >-
        chown -R ghrunner:ghrunner {{ github_runner_settings.install_dir }} &&
        chmod -R u=rwX,g=rX,o-rwx {{ github_runner_settings.install_dir }}
    - onchanges:
      - cmd: "GitHub Runner Software"

"GitHub Runner Service":
  cmd.run:
    - name: >-
        {{ github_runner_settings.install_dir }}/svc.{{
          github_runner_settings.script_suffix
        }} install ghrunner
    - cwd: {{ github_runner_settings.install_dir }}
    - creates: {{ github_runner_settings.install_dir }}/.service
    - require:
      - cmd: "GitHub Runner Software"
      - cmd: "Secure {{ github_runner_settings.install_dir }}"

"Enable GitHub Runner Service":
{%- if salt["file.file_exists"](github_runner_settings.install_dir ~ '/.service') %}
  service.running:
    - name: {{
        salt['cmd.run'](
          "cat '" ~ github_runner_settings.install_dir ~ "/.service'"
        )
      }}
    - enable: True
    - require:
      - cmd: "GitHub Runner Service"
{%- else %}
  cmd.run:
    - name: >-
        SERVICE=$(cat {{ github_runner_settings.install_dir }}/.service);
        systemctl enable $SERVICE;
        systemctl start $SERVICE
    - require:
      - cmd: "GitHub Runner Service"
{%- endif %}
