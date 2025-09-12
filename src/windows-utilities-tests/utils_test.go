package wuts_test

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"text/template"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
	"gopkg.in/yaml.v2"

	. "github.com/cloudfoundry/windows-utilities-release/windows-utilities-tests/templates"
)

const BOSH_TIMEOUT = 90 * time.Minute

type ManifestProperties struct {
	DeploymentName  string
	ReleaseName     string
	AZ              string
	VmType          string
	VmExtensions    string
	Network         string
	StemcellOS      string
	StemcellVersion string
	WinUtilVersion  string
	WutsVersion     string
}

type Config struct {
	Bosh struct {
		CaCert       string `json:"ca_cert"`
		Client       string `json:"client"`
		ClientSecret string `json:"client_secret"`
		Target       string `json:"target"`
	} `json:"bosh"`
	StemcellPath               string `json:"stemcell_path"`
	WindowsUtilitiesPath       string `json:"windows_utilities_path"`
	StemcellOS                 string `json:"stemcell_os"`
	Az                         string `json:"az"`
	VmType                     string `json:"vm_type"`
	VmExtensions               string `json:"vm_extensions"`
	Network                    string `json:"network"`
	WindowsSSHFirewallRuleName string `json:"windows_ssh_firewall_rule_name"`
	SkipCleanup                bool   `json:"skip_cleanup"`
	SkipCleanupOnRDPFail       bool   `json:"skip_cleanup_on_rdp_fail"`
}

func NewConfig() (*Config, error) {
	configFilePath := os.Getenv("CONFIG_JSON")
	if configFilePath == "" {
		return nil, fmt.Errorf("invalid config file path: %v", configFilePath)
	}
	body, err := ioutil.ReadFile(configFilePath)
	if err != nil {
		return nil, fmt.Errorf("empty config file path: %v", configFilePath)
	}
	var config Config
	err = json.Unmarshal(body, &config)
	if err != nil {
		return nil, fmt.Errorf("unable to parse config file: %v", body)
	}
	return &config, nil
}

func (c *Config) newManifestProperties(deploymentName string) ManifestProperties {
	log.Println("BeforeSuite: releaseVersion =", releaseVersion)
	log.Println("BeforeSuite: winUtilRelVersion =", winUtilRelVersion)
	return ManifestProperties{
		DeploymentName:  deploymentName,
		ReleaseName:     "wuts-release",
		AZ:              c.Az,
		VmType:          c.VmType,
		VmExtensions:    c.VmExtensions,
		Network:         c.Network,
		StemcellOS:      c.StemcellOS,
		StemcellVersion: stemcellInfo.Version,
		WinUtilVersion:  winUtilRelVersion,
		WutsVersion:     releaseVersion,
	}
}

func (*Config) generateManifestFile(manifestProperties interface{}, manifestTemplate string) (string, error) {
	templ, err := template.New("").Parse(manifestTemplate)
	if err != nil {
		return "", err
	}

	var buf bytes.Buffer
	err = templ.Execute(&buf, manifestProperties)
	if err != nil {
		return "", err
	}

	manifestFile, err := ioutil.TempFile("", "")
	if err != nil {
		return "", err
	}

	manifest := buf.Bytes()
	log.Print("\nManifest: " + string(manifest[:]) + "\n")
	_, err = manifestFile.Write(manifest)
	if err != nil {
		return "", err
	}

	return filepath.Abs(manifestFile.Name())
}

func (c *Config) generateDefaultManifest(deploymentName string) (string, error) {
	return c.generateManifestFile(c.newManifestProperties(deploymentName), ManifestTemplate)
}

type SSHManifestProperties struct {
	ManifestProperties
	SSHEnabled       bool
	FirewallRuleName string
}

func (c *Config) generateManifestSSH(deploymentName string, enabled bool) (string, error) {
	manifestProperties := SSHManifestProperties{
		ManifestProperties: c.newManifestProperties(deploymentName),
		SSHEnabled:         enabled,
		FirewallRuleName:   c.WindowsSSHFirewallRuleName,
	}
	return c.generateManifestFile(manifestProperties, SSHTemplate)
}

type RDPManifestProperties struct {
	ManifestProperties
	RDPEnabled         bool
	SetPasswordEnabled bool
	InstanceName       string
	Username           string
	Password           string
}

func (c *Config) generateManifestRDP(deploymentName string, instanceName string, enabled bool, username string, password string) (string, error) {
	manifestProperties := RDPManifestProperties{
		ManifestProperties: c.newManifestProperties(deploymentName),
		RDPEnabled:         enabled,
		SetPasswordEnabled: enabled,
		InstanceName:       instanceName,
		Username:           username,
		Password:           password,
	}

	return c.generateManifestFile(manifestProperties, RDPTemplate)
}

type DefenderManifestProperties struct {
	ManifestProperties
	DefenderEnabled bool
}

func (c *Config) generateManifestWindowsDefender(deploymentName string, enabled bool) (string, error) {
	manifestProperties := DefenderManifestProperties{
		ManifestProperties: c.newManifestProperties(deploymentName),
		DefenderEnabled:    enabled,
	}

	return c.generateManifestFile(manifestProperties, DefenderTemplate)
}

func (c *Config) generateManifestWindowsDefenderChecker(deploymentName string) (string, error) {
	manifestProperties := DefenderManifestProperties{ManifestProperties: c.newManifestProperties(deploymentName)}

	return c.generateManifestFile(manifestProperties, DefenderNotPresentTemplate)
}

type BoshCommand struct {
	DirectorIP   string
	Client       string
	ClientSecret string
	CertPath     string // Path to CA CERT file, if any
	Timeout      time.Duration
}

func NewBoshCommand(config *Config, CertPath string, duration time.Duration) *BoshCommand {
	return &BoshCommand{
		DirectorIP:   config.Bosh.Target,
		Client:       config.Bosh.Client,
		ClientSecret: config.Bosh.ClientSecret,
		CertPath:     CertPath,
		Timeout:      duration,
	}
}

func (c *BoshCommand) args(command string) []string {
	args := strings.Split(command, " ")
	args = append([]string{"-n", "-e", c.DirectorIP, "--client", c.Client, "--client-secret", c.ClientSecret}, args...)
	if c.CertPath != "" {
		args = append([]string{"--ca-cert", c.CertPath}, args...)
	}
	return args
}

func (c *BoshCommand) Run(command string) error {
	cmd := exec.Command("bosh", c.args(command)...)
	log.Printf("\nRUNNING %q\n", strings.Join(cmd.Args, " "))

	session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
	if err != nil {
		return err
	}
	session.Wait(c.Timeout)

	exitCode := session.ExitCode()
	if exitCode != 0 {
		var stderr []byte
		if session.Err != nil {
			stderr = session.Err.Contents()
		}
		stdout := session.Out.Contents()
		return fmt.Errorf("Non-zero exit code for cmd %q: %d\nSTDERR:\n%s\nSTDOUT:%s\n",
			strings.Join(cmd.Args, " "), exitCode, stderr, stdout)
	}
	return nil
}

func (c *BoshCommand) RunInStdOut(command, dir string) ([]byte, error) {
	cmd := exec.Command("bosh", c.args(command)...)
	if dir != "" {
		cmd.Dir = dir
		log.Printf("\nRUNNING %q IN %q\n", strings.Join(cmd.Args, " "), dir)
	} else {
		log.Printf("\nRUNNING %q\n", strings.Join(cmd.Args, " "))
	}

	session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
	if err != nil {
		return nil, err
	}
	session.Wait(c.Timeout)

	exitCode := session.ExitCode()
	stdout := session.Out.Contents()
	if exitCode != 0 {
		var stderr []byte
		if session.Err != nil {
			stderr = session.Err.Contents()
		}
		return stdout, fmt.Errorf("Non-zero exit code for cmd %q: %d\nSTDERR:\n%s\nSTDOUT:%s\n",
			strings.Join(cmd.Args, " "), exitCode, stderr, stdout)
	}
	return stdout, nil
}

func runCommand(cmd string, args ...string) (*Session, error) {
	return Start(exec.Command(cmd, args...), GinkgoWriter, GinkgoWriter)
}

// noinspection GoUnusedFunction
func downloadLogs(deploymentName string, jobName string, index int) *Buffer {
	tempDir, err := ioutil.TempDir("", "")
	Expect(err).To(Succeed())
	defer os.RemoveAll(tempDir)

	err = bosh.Run(fmt.Sprintf("-d %s logs %s/%d --dir %s", deploymentName, jobName, index, tempDir))
	Expect(err).To(Succeed())

	matches, err := filepath.Glob(filepath.Join(tempDir, fmt.Sprintf("%s.%s.%d-*.tgz", deploymentName, jobName, index)))
	Expect(err).To(Succeed())
	Expect(matches).To(HaveLen(1))

	cmd := exec.Command("tar", "xf", matches[0], "-O", fmt.Sprintf("./%s/%s/job-service-wrapper.out.log", jobName, jobName))
	session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
	Expect(err).To(Succeed())

	return session.Wait().Out
}

type vmInfo struct {
	Tables []struct {
		Rows []struct {
			Instance string `json:"instance"`
			IPs      string `json:"ips"`
		} `json:"Rows"`
	} `json:"Tables"`
}

type ManifestInfo struct {
	Version string `yaml:"version"`
	Name    string `yaml:"name"`
}

func fetchManifestInfo(releasePath string, manifestFilename string) (ManifestInfo, error) {
	var stemcellInfo ManifestInfo
	tempDir, err := ioutil.TempDir("", "")
	Expect(err).To(Succeed())
	defer os.RemoveAll(tempDir)

	cmd := exec.Command("tar", "xf", releasePath, "-C", tempDir, manifestFilename)
	session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
	Expect(err).To(Succeed())
	session.Wait(20 * time.Minute)

	exitCode := session.ExitCode()
	if exitCode != 0 {
		var stderr []byte
		if session.Err != nil {
			stderr = session.Err.Contents()
		}
		stdout := session.Out.Contents()
		return stemcellInfo, fmt.Errorf("Non-zero exit code for cmd %q: %d\nSTDERR:\n%s\nSTDOUT:%s\n",
			strings.Join(cmd.Args, " "), exitCode, stderr, stdout)
	}

	stemcellMF, err := ioutil.ReadFile(fmt.Sprintf("%s/%s", tempDir, manifestFilename))
	Expect(err).To(Succeed())

	err = yaml.Unmarshal(stemcellMF, &stemcellInfo)
	Expect(err).To(Succeed())
	Expect(stemcellInfo.Version).ToNot(BeNil())
	Expect(stemcellInfo.Version).ToNot(BeEmpty())

	return stemcellInfo, nil
}

func writeCert(cert string) string {
	if cert != "" {
		certFile, err := ioutil.TempFile("", "")
		Expect(err).To(Succeed())

		_, err = certFile.Write([]byte(cert))
		Expect(err).To(Succeed())

		boshCertPath, err := filepath.Abs(certFile.Name())
		Expect(err).To(Succeed())
		return boshCertPath
	}
	return ""
}

func createAndUploadRelease(releaseDir string) string {
	pwd, err := os.Getwd()
	Expect(err).To(Succeed())

	absoluteFilePath := releaseDir
	if !filepath.IsAbs(absoluteFilePath) {
		absoluteFilePath = filepath.Join(pwd, releaseDir)
	}
	Expect(os.Chdir(absoluteFilePath)).To(Succeed())
	defer os.Chdir(pwd)

	version := fmt.Sprintf("0.dev+%d", getTimestampInMs())

	Expect(bosh.Run(fmt.Sprintf("create-release --force --version %s", version))).To(Succeed())
	Expect(bosh.Run("upload-release")).To(Succeed())

	return version
}

func getTimestampInMs() int64 {
	return time.Now().UTC().UnixNano() / int64(time.Millisecond)
}

func generateSemiRandomWindowsPassword() string {
	var (
		validChars []rune
		password   string
	)

	for i := '!'; i <= '~'; i++ {
		if i != '\'' && i != '"' && i != '`' && i != '\\' {
			validChars = append(validChars, i)
		}
	}

	for i := 0; i < 10; i++ {
		randomIndex := rand.Intn(len(validChars))
		password = password + string(validChars[randomIndex])
	}

	// ensure compliance with Windows password requirements
	password = password + "Ab!"
	return password
}

func getFirstInstanceIP(deployment string, instanceName string) (string, error) {
	var vms vmInfo
	stdout, err := bosh.RunInStdOut(fmt.Sprintf("vms -d %s --json", deployment), "")
	if err != nil {
		return "", err
	}

	if err = json.Unmarshal(stdout, &vms); err != nil {
		return "", err
	}

	for _, row := range vms.Tables[0].Rows {
		if strings.HasPrefix(row.Instance, instanceName) {
			ips := strings.Split(row.IPs, "\n")
			if len(ips) == 0 {
				break
			}
			return ips[0], nil
		}
	}

	return "", errors.New("No instance IPs found!")
}
