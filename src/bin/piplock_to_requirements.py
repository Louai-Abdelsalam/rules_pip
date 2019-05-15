import json
import sys


def piplock_to_requirements(lock_file=None, requirements_file=None):
    requirements = []

    if lock_file:
        with open(lock_file, 'r') as f:
            lf = json.loads(f.read())

        if lf:
            requirements += "# DO NOT EDIT - auto generated from {}\n".format(lock_file)

            # Join both our default and develop requirements
            req = [('{}{}'.format(x, y.get('version')), y.get('hashes')) for x, y in lf.get('default', {}).items()]
            req += [('{}{}'.format(x, y.get('version')), y.get('hashes')) for x, y in lf.get('develop', {}).items()]

            # 'Things' seem to need setup tools, but don't explicitly list it, so just add it in here
            req += [('setuptools==41.0.1', ['sha256:c7769ce668c7a333d84e17fe8b524b1c45e7ee9f7908ad0a73e1eda7e6a5aebf'])]

            # Loop over each and build our requirement file
            for module, hashes in req:
                requirements += '{} \\\n'.format(module)
                requirements += '\n'.join(['    --hash={} \\'.format(h) for h in hashes])
                requirements += '\n\n'
    else:
        raise ValueError('An input Pipfile.lock must be specified.')

    if requirements_file:
        if requirements:
            with open(requirements_file, 'w+') as f:
                f.writelines(requirements)
    else:
        raise ValueError('An output requirements file must be specified.')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: {} lock_file requirements_file'.format(sys.argv[0]))
        exit(-1)

    lock_file = sys.argv[1]
    requirements_file = sys.argv[2]

    piplock_to_requirements(lock_file, requirements_file)