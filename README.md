## Windows Utilities Release

The Windows Utilities Release provides BOSH jobs intended to be used as [addons](http://bosh.io/docs/runtime-config.html#addons), that help operators configure the operating system.

See [os-conf-release](https://github.com/cloudfoundry/os-conf-release) for Linux OS Configuration.

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

**Note:** The `set_password` job should not be used in conjunction with the `randomize_password` job.

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
    release: windows-utilities
  include:
    stemcell:
    - os: windows2012R2
```

Note that all of these jobs can be disabled by adding `enabled: false` to their properties.

### Using These Jobs to RDP With a Remote Desktop Client

To RDP to a windows VM,
you can use three of these jobs in conjunction:

- enable_rdp
- enable_ssh - to make it easy to setup a tunnel with the BOSH CLI
- set_password - alternatively, you may be able to setup a user using your IaaS

To create a tunnel for your RDP client:
```
bosh ssh -d <deployment> <job> --opts='-L 3389:<internal-ip-of-job>:3389'
```

Then use your RDP client to connect to `localhost:3389`
using the password set for the `set_password` job.
**Warning:** Bosh `--vars-store` variable generation
will not be able to fulfill the [complexity requirements][password-reqs],
as it does not include upper-case letters.
This will not cause the job to fail, however the password will not work.
If you're using --vars-store, you'll need to pass the password
in with a vars file or `-v` arg at deployment time.
If you have a bosh director with a credhub,
you may have better luck with password generation.

To launch powershell (or other programs),
first do Ctl + Shift + Esc to open task manager,
Click "More details" in the lower left hand corner,
and then `File>Run New Task`.
Type `powershell`.

[password-reqs]: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
