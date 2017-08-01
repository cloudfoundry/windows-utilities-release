## Windows Utility Release

The Windows Utility Release provides [BOSH Addons](http://bosh.io/docs/runtime-config.html#addons) that allows operators to: enable [BOSH SSH](https://bosh.io/docs/cli-v2.html#errand-mgmt) and set or randomize the Windows password.

#### Example runtime configuration:

```yaml
---
releases:
- name: windows-utilities
  version: 0+dev.16

addons:
- name: enable-ssh
  jobs:
  - name: enable-ssh
    release: windows-utilities
    properties: {}
  include:
    stemcell:
    - os: windows2012R2
- name: set-password
  jobs:
  - name: set-admin-password
    release: windows-utilities
    properties:
      set-admin-password:
        username: "Administrator"
        # Explicitly set a password for all Windows VMs.  Note: the password
        # must be Windows password complexity rules.
        password: "Foobar123!"
        # Uncomment the 'randomize-password' field to have random a password
        # generated for each Windows VM. To use you must comment out or remove
        # the 'password' field.
        # randomize-password: true
  include:
    stemcell:
    - os: windows2012R2
```
