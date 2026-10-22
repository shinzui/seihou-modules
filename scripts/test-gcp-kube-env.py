#!/usr/bin/env python3
"""Exercise cloud setup through real Seihou, kubectl and direnv, without a cluster."""

import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONTEXT = 'gke_tan-cluster_us-west1-a_sennari'
OTHER = "another context's name"
TOKEN = 'fixture-credential-must-never-enter-seihou-baselines'


class CloudEnvironmentTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='gcp-kube-env-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.project = self.base / "checkout with spaces and 'quotes'"
        self.project.mkdir()
        self.home = self.base / 'home'
        (self.home / '.kube').mkdir(parents=True)
        self.source = self.home / '.kube/config'
        self.source.write_text(json.dumps({
            'apiVersion': 'v1', 'kind': 'Config',
            'current-context': OTHER,
            'contexts': [
                {'name': name, 'context': {'cluster': name, 'user': 'fixture'}}
                for name in (CONTEXT, OTHER)
            ],
            'clusters': [
                {'name': name, 'cluster': {'server': 'https://127.0.0.1:6443'}}
                for name in (CONTEXT, OTHER)
            ],
            'users': [{'name': 'fixture', 'user': {'token': TOKEN}}],
        }))
        self.original_source = self.source.read_bytes()
        self.env = os.environ.copy()
        # Isolate global Seihou settings and prevent inherited direnv state from
        # selecting a developer's real kubeconfig or project configuration.
        for key in list(self.env):
            if key.startswith(('DIRENV_', 'SEIHOU_')):
                self.env.pop(key)
        self.env.update({
            'HOME': str(self.home),
            'XDG_CONFIG_HOME': str(self.home / '.config'),
            'KUBECONFIG': str(self.source),
            'CLOUDSDK_CORE_PROJECT': 'original-project',
            'GOOGLE_CLOUD_PROJECT': 'original-project',
        })
        shutil.copytree(ROOT / 'modules/cloud/gcp-kube-env',
                        self.project / '.seihou/modules/gcp-kube-env')
        self.run_cmd(['git', 'init', '-q'])

    def run_cmd(self, args, *, env=None, success=True):
        result = subprocess.run(args, cwd=self.project, env=env or self.env,
                                text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, f'{args}:\n{result.stdout}\n{result.stderr}')
        else:
            self.assertNotEqual(result.returncode, 0, f'{args} unexpectedly succeeded')
        return result

    def apply(self, *, project='tan-ng', context=CONTEXT, filename=None, **kwargs):
        command = ['seihou', 'run', 'gcp-kube-env', '--no-save-prompted',
                   '--var', f'gcp.project={project}', '--var', f'k8s.context={context}']
        if filename is not None:
            command += ['--var', f'env.file={filename}']
        return self.run_cmd(command, **kwargs)

    def loaded(self):
        # Evaluate the actual direnv loader without invoking a user's Nix shell.
        stdlib = self.run_cmd(['direnv', 'stdlib']).stdout
        script = stdlib + '\nsource ./.envrc\n' + """
kubectl config current-context
printf '%s\\n' "$CLOUDSDK_CORE_PROJECT" "$GOOGLE_CLOUD_PROJECT" "$KUBECONFIG"
"""
        return self.run_cmd(['bash', '-e', '-c', script]).stdout.splitlines()

    def test_default_preserves_settings_and_isolates_credentials(self):
        (self.project / '.envrc').write_text('export EXISTING_LOADER=yes\n')
        (self.project / '.envrc.local').write_text('export PERSONAL_SETTING=keep\n')
        (self.project / '.gitignore').write_text('existing-ignore\n')
        self.apply()
        loaded = self.loaded()
        self.assertEqual(loaded[:3], [CONTEXT, 'tan-ng', 'tan-ng'])
        kube = Path(loaded[3])
        self.assertEqual(stat.S_IMODE(kube.stat().st_mode), 0o600)
        env_file = self.project / '.envrc.local'
        self.assertEqual(stat.S_IMODE(env_file.stat().st_mode), 0o600)
        self.assertIn('export PERSONAL_SETTING=keep\n', env_file.read_text())
        self.assertTrue((self.project / '.envrc').read_text().startswith('export EXISTING_LOADER=yes\n'))
        self.assertTrue((self.project / '.gitignore').read_text().startswith('existing-ignore\n'))
        self.assertEqual(self.source.read_bytes(), self.original_source)
        self.assertEqual(self.run_cmd(['kubectl', 'config', 'current-context']).stdout.strip(), OTHER)
        snapshot = json.loads(kube.read_text())
        self.assertEqual([item['name'] for item in snapshot['contexts']], [CONTEXT])
        self.assertEqual(snapshot['users'][0]['user']['token'], TOKEN)
        for path in (self.project / '.seihou').rglob('*'):
            if path.is_file():
                self.assertNotIn(TOKEN, path.read_text(), f'Credential leaked into {path}')
        self.run_cmd(['git', 'check-ignore', '.envrc.local', str(kube.relative_to(self.project))])
        before = {p: p.read_bytes() for p in [env_file, kube, self.project / '.envrc', self.project / '.gitignore']}
        self.apply()
        self.assertEqual({p: p.read_bytes() for p in before}, before)

    def test_custom_dotenv_filename_and_reconfiguration(self):
        (self.project / '.env').write_text('PERSONAL_SETTING=keep\n')
        self.apply(filename='.env')
        self.assertFalse((self.project / '.envrc.local').exists())
        self.assertEqual(self.loaded()[:3], [CONTEXT, 'tan-ng', 'tan-ng'])
        # A .env file remains usable by direnv's dotenv parser as well.
        self.run_cmd(['bash', '-e', '-c',
                      'eval "$(direnv dotenv bash .env)"; test "$GOOGLE_CLOUD_PROJECT" = tan-ng'])
        self.apply(project='another-project', context=OTHER, filename='.env')
        self.assertEqual(self.loaded()[:3], [OTHER, 'another-project', 'another-project'])
        self.assertEqual((self.project / '.env').read_text().count('# >>> seihou:gcp-kube-env'), 1)
        self.assertEqual((self.project / '.envrc').read_text().count('source_env_if_exists .env'), 1)
        self.assertIn('PERSONAL_SETTING=keep\n', (self.project / '.env').read_text())

    def test_retarget_from_activated_snapshot_and_repair(self):
        self.apply()
        active = dict(self.env, KUBECONFIG=str(self.project / '.direnv/../.direnv/gcp-kube-env.kubeconfig'))
        self.apply(context=OTHER, env=active)
        self.assertEqual(self.loaded()[0], OTHER)
        (self.project / '.envrc.local').unlink()
        (self.project / '.direnv/gcp-kube-env.kubeconfig').unlink()
        self.run_cmd(['python3', 'scripts/setup-gcp-kube-env.py'], env=active)
        self.assertEqual(self.loaded()[0], OTHER)
        self.assertEqual(self.source.read_bytes(), self.original_source)

    def test_missing_context_does_not_modify_local_settings(self):
        (self.project / '.envrc.local').write_text('export KEEP=yes\n')
        self.apply(context='missing-context', success=False)
        self.assertEqual((self.project / '.envrc.local').read_text(), 'export KEEP=yes\n')
        self.assertFalse((self.project / '.direnv').exists())
        self.assertFalse((self.project / '.envrc').exists())

    def test_rejects_unsafe_filenames_without_shell_execution(self):
        for filename in ['../outside', '.envrc', '.gitignore', '.', '..',
                         ".env'; touch unexpected; #"]:
            with self.subTest(filename=filename):
                self.apply(filename=filename, success=False)
        self.assertFalse((self.project / 'unexpected').exists())
        self.assertFalse((self.project / '.envrc').exists())
        self.assertFalse((self.base / 'outside').exists())

    def test_rejects_symlinks_and_malformed_blocks(self):
        outside = self.base / 'outside'
        outside.write_text('keep\n')
        env_file = self.project / '.envrc.local'
        env_file.symlink_to(outside)
        self.apply(success=False)
        self.assertEqual(outside.read_text(), 'keep\n')
        env_file.unlink()
        env_file.write_text('# >>> seihou:gcp-kube-env\nexport KEEP=yes\n')
        self.apply(success=False)
        self.assertEqual(env_file.read_text(), '# >>> seihou:gcp-kube-env\nexport KEEP=yes\n')
        self.assertFalse((self.project / '.direnv').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
