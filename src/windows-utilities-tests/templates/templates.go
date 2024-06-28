package templates

const ManifestTemplate = `
---
name: {{.DeploymentName}}

releases:
- name: {{.ReleaseName}}
  version: {{.WutsVersion}}
- name: windows-utilities
  version: '{{.WinUtilVersion}}'

stemcells:
- alias: windows
  os: {{.StemcellOS}}
  version: '{{.StemcellVersion}}'

update:
  canaries: 0
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: 2

instance_groups:
- name: kms-host-enabled
  instances: 1
  stemcell: windows
  lifecycle: errand
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: check_kms_host
    release: {{.ReleaseName}}
    properties:
      check_kms_host:
        host: test.test
        port: 1234
  - name: set_kms_host
    release: windows-utilities
    properties:
      set_kms_host:
        enabled: true
        host: test.test
        port: 1234
- name: kms-host-not-enabled
  instances: 1
  stemcell: windows
  lifecycle: errand
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: check_kms_host
    release: {{.ReleaseName}}
    properties:
      check_kms_host:
        host:
        port:
  - name: set_kms_host
    release: windows-utilities
    properties:
      set_kms_host:
        enabled: false
        host: test.test
        port: 1234
- name: kms-host-enabled-with-default
  instances: 1
  stemcell: windows
  lifecycle: errand
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: check_kms_host
    release: {{.ReleaseName}}
    properties:
      check_kms_host:
        host: test.test
        port: 1688
  - name: set_kms_host
    release: windows-utilities
    properties:
      set_kms_host:
        enabled: true
        host: test.test
        port:
- name: set-admin-password
  instances: 1
  stemcell: windows
  lifecycle: errand
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: check_set_password
    release: {{.ReleaseName}}
  - name: set_password
    release: windows-utilities
    properties:
      set_password:
        username: "Administrator"
        password: "Password123!"
`

const SSHTemplate = `
---
name: {{.DeploymentName}}

releases:
- name: {{.ReleaseName}}
  version: {{.WutsVersion}}
- name: windows-utilities
  version: '{{.WinUtilVersion}}'

stemcells:
- alias: windows
  os: {{.StemcellOS}}
  version: '{{.StemcellVersion}}'

update:
  canaries: 0
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: 2

instance_groups:
- name: check-ssh
  instances: 1
  stemcell: windows
  lifecycle: service # run as service
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: enable_ssh
    release: windows-utilities
    properties:
      enable_ssh:
        enabled: {{.SSHEnabled}}
  - name: check_ssh
    release: {{.ReleaseName}}
    properties:
      check_ssh:
        expected: {{.SSHEnabled}}
`

const RDPTemplate = `
---
name: {{.DeploymentName}}

releases:
- name: {{.ReleaseName}}
  version: '{{.WutsVersion}}'
- name: windows-utilities
  version: '{{.WinUtilVersion}}'

stemcells:
- alias: windows
  os: {{.StemcellOS}}
  version: '{{.StemcellVersion}}'

update:
  canaries: 0
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: 2

instance_groups:
- name: {{.InstanceName}}
  instances: 1
  stemcell: windows
  lifecycle: service # run as service
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: enable_rdp
    release: windows-utilities
    properties:
      enable_rdp:
        enabled: {{.RDPEnabled}}
  - name: set_password
    release: windows-utilities
    properties:
      set_password:
        enabled: {{.RDPEnabled}}
        username: 'Administrator'
        password: '{{.Password}}'
  - name: check_rdp
    release: {{.ReleaseName}}
    properties:
      check_rdp:
        expected: {{.RDPEnabled}}
`

const DefenderTemplate = `
---
name: {{.DeploymentName}}

releases:
- name: {{.ReleaseName}}
  version: '{{.WutsVersion}}'
- name: windows-utilities
  version: '{{.WinUtilVersion}}'

stemcells:
- alias: windows
  os: {{.StemcellOS}}
  version: '{{.StemcellVersion}}'

update:
  canaries: 0
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: 2

instance_groups:
- name: check-windowsdefender
  instances: 1
  stemcell: windows
  lifecycle: service # run as service
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: enable_windowsdefender
    release: windows-utilities
    properties:
      enable_windowsdefender:
        enabled: {{.DefenderEnabled}}
  - name: check_windowsdefender
    release: {{.ReleaseName}}
    properties:
      check_windowsdefender:
        expected: {{.DefenderEnabled}}
`

const DefenderNotPresentTemplate = `
---
name: {{.DeploymentName}}

releases:
- name: {{.ReleaseName}}
  version: '{{.WutsVersion}}'

stemcells:
- alias: windows
  os: {{.StemcellOS}}
  version: '{{.StemcellVersion}}'

update:
  canaries: 0
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: 2

instance_groups:
- name: check-windowsdefender
  instances: 1
  stemcell: windows
  lifecycle: service # run as service
  azs: [{{.AZ}}]
  vm_type: {{.VmType}}
  vm_extensions: [{{.VmExtensions}}]
  networks:
  - name: {{.Network}}
  jobs:
  - name: check_windowsdefender
    release: {{.ReleaseName}}
    properties:
      check_windowsdefender:
        expected: false
`
