package suites

import (
	"testing"

	"github.com/mesosphere/kommander-applications/apptests/catalog"
)

// skipApps are excluded from auto-registered E2E tests; every other app under
// applications/ gets a default install + upgrade test.
var skipApps = []string{
	// TODO: non-standard layout + deps

	"ndk", "nutanix-ai",
	// TODO: need dependencies
	"opentelemetry-operator",
}

//nolint:gochecknoinits // init required for test registration before suite runs
func init() {
	catalog.InitSuite()
	skip := make(map[string]bool, len(skipApps))
	for _, a := range skipApps {
		skip[a] = true
	}

	catalog.ScanAndRegister("../..", skip)
}

func TestApplications(t *testing.T) { catalog.RunSuite(t) }
