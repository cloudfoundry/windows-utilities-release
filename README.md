## Windows Utilities Release

The Windows Utilities Release provides BOSH jobs intended to be used as [addons](http://bosh.io/docs/runtime-config.html#addons), that help operators configure the operating system.

See [os-conf-release(https://github.com/cloudfoundry/os-conf-release) for Linux OS Configuration.

### Example Runtime Configurations

Include the release in your runtime-config.yml:
```yaml
---
releases:
...
- name: windows-utilities
  version: <some-version>
```

#### Setting a password:
```yaml
addons:
...
- name: <some-name>
  jobs:
  - name: set_password
    release: windows-utilities
    properties:
      set_password:
        username: "SomeUser" # defaults to "Administrator"
        password: "Foobar123!" # must meet default Windows complexity requirements
  include:
    stemcell:
    - os: windows2012R2
```

#### Randomizing each VM's password
```yaml
addons:
- name: <some-name>
  jobs:
  - name: randomize_password
    release: windows-utilities
    properties:
      randomize_password:
        username: "SomeUser" # defaults to "Administrator"
  include:
    stemcell:
    - os: windows2012R2
```

#### Enabling experimental BOSH SSH support on Windows
```yaml
addons:
- name: <some-name>
  jobs:
  - name: enable_ssh
    release: windows-utilities
  include:
    stemcell:
    - os: windows2012R2
```

#### Configuring a KMS host for your volume-licensed Windows VM to register and activate with
```yaml
addons:
- name: <some-name>
  jobs:
  - name: set_kms_host
    release: windows-utilities
    properties:
      set_kms_host:
        host: some-kms-host.privatedomainname
        port: 12345 # defaults to 1688
  include:
    stemcell:
    - os: windows2012R2
```

#### Enabling RDP access for Administrators on your Windows Cell
```yaml
addons:
- name: <some-name>
  jobs:
  - name: enable_rdp
    properties:
      enable_rdp:
        enabled: true
    release: windows-utilities
  include:
    stemcell:
    - os: windows2012R2
```

Note that all of these jobs can be disabled by adding `enabled: false` to their properties.
