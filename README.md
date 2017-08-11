## Windows Utility Release

The Windows Utility Release provides [BOSH Addons](http://bosh.io/docs/runtime-config.html#addons) that allows operators to: enable [BOSH SSH](https://bosh.io/docs/cli-v2.html#errand-mgmt) and set or randomize the Windows password.

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
- name: set_password
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
- name: randomize_password
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
- name: enable_ssh
  jobs:
  - name: enable_ssh
    release: windows-utilities
  include:
    stemcell:
    - os: windows2012R2
```

Note that all of these jobs can be disabled by adding `enabled: false` to their properties.
