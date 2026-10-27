#!/usr/bin/env python3
"""Live acceptance of a fresh scaffold. Resources are private to this run.

Run --live on the authoring host; it renders once and enters the generated shell.
Logs and fixtures are retained for inspection, while services/databases always stop.
"""
import argparse
import importlib.util
import json
import os
import pwd
import time
from pathlib import Path
import signal
import socket
import subprocess
import tempfile

SPEC = importlib.util.spec_from_file_location('keiro_check', Path(__file__).with_name('check-keiro-bootstrap.py'))
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


def port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


class Commands:
    def __init__(self, project):
        self.project = project
        self.logs = project / '.artifacts/acceptance'
        self.logs.mkdir(parents=True, exist_ok=True)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("HINAGATA_")}
        self.index = 0

    def run(self, args, success=True, timeout=1800):
        self.index += 1
        label = f'{self.index:02d}-{Path(args[0]).name}'
        print('RUN', ' '.join(map(str, args)), flush=True)
        child = subprocess.Popen(list(map(str, args)), cwd=self.project, env=self.env,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                                 start_new_session=True)
        try:
            out, err = child.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGTERM)
            try:
                out, err = child.communicate(timeout=15)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                out, err = child.communicate()
            (self.logs / (label + ".out")).write_text(out)
            (self.logs / (label + ".err")).write_text(err)
            raise AssertionError(f'Timed out: {args}; {err[-3000:]}')
        finally:
            if child.poll() is None:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
        (self.logs / (label + '.out')).write_text(out)
        (self.logs / (label + '.err')).write_text(err)
        if success and child.returncode:
            raise AssertionError(f'{args}: exit {child.returncode}\n{out[-4000:]}\n{err[-6000:]}')
        return subprocess.CompletedProcess(args, child.returncode, out, err)


def consumer(project):
    # This auxiliary executable exists only in the acceptance fixture.
    d = project / 'acceptance'
    d.mkdir()
    (project / 'cabal.project').write_text((project / 'cabal.project').read_text() + '\npackages: acceptance\n')
    (d / 'acceptance.cabal').write_text('''cabal-version: 3.4
name: acceptance
version: 0.1.0.0
build-type: Simple
executable acceptance
  default-language: GHC2024
  default-extensions: OverloadedStrings TypeApplications
  hs-source-dirs: .
  main-is: Main.hs
  ghc-options: -threaded
  build-depends: base, aeson, process, servant, servant-server, servant-health,
    warp, transformers, sample-service-api, sample-service-server
''')
    (d / 'Main.hs').write_text('''module Main (main) where
import Data.Aeson (Value, object, (.=))
import Data.Proxy (Proxy (..))
import Network.Wai.Handler.Warp qualified as Warp
import Servant.API (NamedRoutes, Get, JSON, (:>), (:<|>) (..))
import Servant.Server (Handler, serve)
import Servant.Health (ProbeVerdict (Healthy))
import Servant.Health.Check (safeCheck, boolCheck)
import SampleService.Api (ServiceApi)
import SampleService.Server.App (serviceServer)
import System.Environment (getEnv)
import System.Process (readProcess)

query :: String -> IO String
query sql = filter (/= '\\n') <$> readProcess "psql" ["-X", "-tAc", sql] ""
marker :: Handler Value
marker = do
  value <- Servant.Server.liftIO (query "SELECT value FROM hinagata_bootstrap.marker WHERE id=1")
  database <- Servant.Server.liftIO (query "SELECT current_database()")
  pure (object ["value" .= value, "database" .= database])
main :: IO ()
main = do
  p <- read <$> getEnv "PORT"
  let readiness = safeCheck "postgres" (boolCheck "postgres" ((== "ready") <$> query "SELECT value FROM hinagata_bootstrap.marker WHERE id=1"))
  Warp.run p $ serve (Proxy @(NamedRoutes ServiceApi :<|> "marker" :> Get '[JSON] Value))
    (serviceServer (pure Healthy) readiness :<|> marker)
'''.replace('import Servant.Server (Handler, serve)', 'import Servant.Server (Handler, serve)\nimport Control.Monad.IO.Class (liftIO)').replace('Servant.Server.liftIO', 'liftIO'))


def inside(project):
    c = Commands(project)
    c.run(['just', 'test-tools'])
    c.run(['just', 'api-validate'])
    rendered = c.run(['just', 'api-render']).stdout
    assert '/health/live' in rendered and '/health/ready' in rendered
    c.run(['just', 'fixture-plan'])
    c.run(['cabal', 'build', 'all', '-j4'])
    c.run(['cabal', 'test', 'all', '-j4'])
    c.run(['just', 'openapi'])
    schema = project / 'docs/openapi.json'
    original = schema.read_bytes()
    c.run(['just', 'openapi'])
    assert schema.read_bytes() == original
    c.run(['just', 'openapi-check'])
    schema.write_bytes(original + b'\n')
    assert c.run(['just', 'openapi-check'], success=False).returncode != 0
    c.run(['just', 'openapi'])
    c.run(['just', 'openapi-check'])
    c.run(['mori', 'validate'])
    inventory = json.loads(c.run(['dhall-to-json', '--file', 'mori.dhall']).stdout)
    assert inventory['apis'][0]['specPath'] == 'docs/openapi.json'
    assert schema.is_file()
    consumer(project)
    c.run(['cabal', 'build', 'acceptance', '-j4'])
    binary = c.run(['cabal', 'list-bin', 'acceptance']).stdout.strip()
    wrapper = project / 'acceptance-service'
    wrapper.write_text('#!/usr/bin/env bash\nset -euo pipefail\nprintf "%s" "$$" > ".artifacts/acceptance/$PGDATABASE.pid"\nprintf "%s" "$PGDATABASE" >> .artifacts/acceptance/databases\nprintf "\\n" >> .artifacts/acceptance/databases\nexec "' + binary + '"\n')
    wrapper.chmod(0o755)
    schema_import = (project / 'hurl-workbench.dhall').read_text().split('in ', 1)[0]
    workspace = schema_import + '''in Schema.Workspace::{
 , schemaVersion = Schema.schemaVersion
 , parameters = [ Schema.Parameter::{ name = "base_url" }, Schema.Parameter::{ name = "service_port" }, Schema.Parameter::{ name = "database", kind = Schema.ParameterKind.Secret } ]
 , fragments = [ Schema.Fragment::{ name = "health", path = "tests/api/health.hurl" }, Schema.Fragment::{ name = "marker", path = "tests/api/marker.hurl" } ]
 , workflows = [ Schema.Workflow::{ name = "check", fragments = [ "health", "marker" ], parameters = [ "base_url", "database" ] } ]
 , recipes = [ Schema.Recipe::{ name = "check", workflow = "check", safety = Schema.Safety.ReadOnly } ]
 , services = [ Schema.Service::{ name = "consumer", command = Schema.CommandSpec::{ executable = "./acceptance-service", environment = [ Schema.EnvironmentBinding::{ variable = "PORT", parameter = "service_port" } ] }, readiness = Schema.Readiness.Http Schema.HttpReadiness::{ url = "http://127.0.0.1:{{service_port}}/health/ready" } } ]
 , suites = [ Schema.Suite::{ name = "check", runs = [ Schema.RunReference.Recipe "check" ], service = Some "consumer", failFast = True } ]
}
'''
    (project / 'acceptance.dhall').write_text(workspace)
    marker = project / 'tests/api/marker.hurl'
    marker.write_text('GET {{base_url}}/health\nHTTP 404\n\nGET {{base_url}}/marker\nHTTP 200\n[Asserts]\nheader "Content-Type" contains "application/json"\njsonpath "$.value" == "ready"\njsonpath "$.database" == "{{database}}"\n')
    # A short socket path avoids PostgreSQL's Unix socket path limit on Darwin.
    cluster = Path(tempfile.mkdtemp(prefix='keiro-pg-', dir='/tmp'))
    data, sockets = cluster / 'data', cluster / 's'
    sockets.mkdir()
    c.env = {key: value for key, value in c.env.items() if not key.startswith("PG")}
    c.env.update(PGHOST=str(sockets), PGPORT=str(port()), PGUSER=pwd.getpwuid(os.getuid()).pw_name, PGDATABASE='postgres')
    psql = lambda sql, db='postgres': c.run(['psql', '-X', '-d', db, '-tAc', sql]).stdout.strip()
    helper = ['bash', 'scripts/keiro-test-env']
    try:
        c.run(['initdb', '-D', data, '--no-locale', '--auth=trust'])
        c.run(['pg_ctl', '-D', data, '-l', cluster / 'postgres.log', '-o', f"-k {sockets} -p {c.env['PGPORT']} -h ''", '-w', 'start'])
        c.run(['createdb', '--', 'bootstrap_sentinel'])
        c.run(['createdb', '--', 'bootstrap_direct'])
        c.run(['just', 'fixture-load', 'bootstrap_direct'])
        c.run(['just', 'fixture-load', 'bootstrap_direct'])
        assert psql('SELECT value FROM hinagata_bootstrap.marker WHERE id=1', 'bootstrap_direct') == 'ready'
        assert psql('SELECT count(*) FROM hinagata_bootstrap.marker', 'bootstrap_direct') == '1'
        assert psql("SELECT to_regclass('hinagata_bootstrap.marker') IS NULL", 'bootstrap_sentinel') == 't'
        c.run(['just', 'fixture-with'])
        databases = []
        for label in ['first', 'second', 'failure']:
            if label == 'failure':
                marker.write_text(marker.read_text().replace('"ready"', '"wrong"'))
            p = port()
            result = c.run(helper + ['db', 'with', '--fixture', 'bootstrap', '--json', '--', 'hurl-workbench', '--workspace', 'acceptance.dhall', 'test', 'suite', 'check', '--variable', f'service_port={p}', '--variable', f'base_url=http://127.0.0.1:{p}', '--secret-env', 'database=PGDATABASE'], success=label != 'failure')
            lease = json.loads(result.stdout)
            assert (result.returncode != 0) == (label == 'failure'), result
            assert lease['disposition'] == 'LeaseReleased', lease
            assert lease['ok'] == (label != 'failure'), lease
            assert lease['status'] == lease['child']['exitCode'] == result.returncode, lease
            if label == 'failure':
                assert 'Assert failure' in result.stderr and 'expected: string <wrong>' in result.stderr, result.stderr
            assert 'SERVICE stopped' in result.stderr, result.stderr
            if label == 'failure':
                assert result.stderr.index('SERVICE stopped') < result.stderr.index('db with: command status'), result.stderr
            observed = (c.logs / 'databases').read_text().splitlines()
            db = observed[-1]
            databases.append(db)
            pid = int((c.logs / f'{db}.pid').read_text())
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                pass
            else:
                raise AssertionError(f'Service {pid} survived lease release')
            inspection = json.loads(c.run(helper + ['inspect', lease['leaseId'], '--json']).stdout)
            assert inspection['candidate']['state'] == 'Released', inspection
            assert psql(f"SELECT count(*) FROM pg_database WHERE datname='{db}'") == '0'
        assert len(set(databases)) == 3, databases
        assert psql("SELECT to_regclass('hinagata_bootstrap.marker') IS NULL", 'bootstrap_sentinel') == 't'
        print('PASS real PostgreSQL fixture, distinct leases, generated probes, Hurl marker assertions, failure propagation, service shutdown and clone cleanup', flush=True)
    finally:
        # Clean up only processes whose executable belongs to this exact fixture.
        for pidfile in c.logs.glob('*.pid'):
            pid = int(pidfile.read_text())
            def owned():
                state = subprocess.run(['ps', '-p', str(pid), '-o', 'command='], text=True, capture_output=True)
                return state.returncode == 0 and state.stdout.strip().split(' ', 1)[0] == binary
            if owned():
                os.kill(pid, signal.SIGTERM)
                deadline = time.monotonic() + 5
                while owned() and time.monotonic() < deadline:
                    time.sleep(0.1)
                if owned():
                    os.kill(pid, signal.SIGKILL)
        if (data / 'postmaster.pid').exists():
            c.run(['pg_ctl', '-D', data, '-m', 'immediate', '-w', 'stop'], timeout=30)
        print(f'Acceptance logs: {c.logs}; PostgreSQL diagnostics: {cluster}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--inside', type=Path, help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.inside:
        inside(args.inside)
    elif args.live:
        project, _, result = CHECK.render(**{'mori.generate': 'true', 'mori.namespace': 'example'})
        assert result.returncode == 0, result.stderr
        print(f'Live fixture ({os.uname().sysname}/{os.uname().machine}): {project}', flush=True)
        subprocess.run(['nix', 'develop', '--no-write-lock-file', '-c', 'python3', str(Path(__file__).resolve()), '--inside', str(project)], cwd=project, check=True)
    else:
        CHECK.main()


if __name__ == '__main__':
    main()
