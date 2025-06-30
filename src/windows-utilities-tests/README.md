# windows-utilities-tests

This repo houses tests used to verify Windows Utilities Release functions as expected.

# Example configuration

You can create a `config.json` file, eg:

```json
{
  "bosh": {
    "ca_cert": "<contents of your bosh director cert, with \n for newlines>",
    "client": "<bosh client name>",
    "client_secret": "<bosh client secret>",
    "target": "<IP of your bosh director>"
  },
  "stemcell_path": "<absolute path to stemcell tgz>",
  "windows_utilities_path": "<absolute path to windows utilities release tgz>",
  "stemcell_os": "<os version, e.g. windows2012R2>",
  "az": "<area zone from bosh cloud config>",
  "vm_type": "<vm_type from bosh cloud config>",
  "vm_extensions": "<comma separated string of options, e.g. 50GB_ephemeral_disk>",
  "network": "<network from bosh cloud config>"
}
```

And then run these tests with `CONFIG_JSON=<path-to-config.json> ginkgo`.  If you need to establish an SSH tunnel to reach the director via a jumpbox, use `windows-utilities-release/ci/shared-scripts/setup-bosh-proxy.sh` before invoking `ginkgo`.

Jobs should be developed in a test driven manner.  Writing tests for our test jobs is important because the feedback loop of running unit tests locally is much faster than the feedback loop we get from running the integration tests on a remote vm.  Jobs with unit tests can be tested by running `Invoke-Pester` in a job's directory on a windows machine.
For example:  running `Invoke-Pester` in `windows-utilities-release/jobs/check_windowsdefender/templates/modules` runs the tests in `CheckWindowsDefender.Tests.ps1`
