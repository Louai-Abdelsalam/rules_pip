def _get_platform(repo_ctx):
    if "mac" in repo_ctx.os.name:
        return "osx"

    return repo_ctx.os.name

def _select_requirements_for_platform(repo_ctx):
    current_platform = _get_platform(repo_ctx)

    for label, intended_platform in repo_ctx.attr.requirements_per_platform.items():
        if intended_platform == current_platform:
            return repo_ctx.path(label)

    fail(
        "None of the given requirements files match the current environment",
        attr = "pip_repository",
    )

def _pip_repository_impl(repo_ctx):
    BUILD_FILE_CONTENT = """
filegroup(
    name = "wheels",
    srcs = glob(["*.whl"]),
    visibility = ["//visibility:public"],
)
    """
    repo_ctx.file("BUILD", BUILD_FILE_CONTENT)

    create_repo_exe_path = repo_ctx.path(repo_ctx.attr._create_repo_exe)
    repo_directory = repo_ctx.path("")

    if repo_ctx.attr.pip_lock:
        requirements_path = repo_ctx.path("requirements.txt")
        repo_ctx.file(requirements_path, content = '')

        repo_ctx.execute([
            repo_ctx.attr.python_interpreter,
            repo_ctx.path(repo_ctx.attr._piplock_to_requirements_exe),
            repo_ctx.path(repo_ctx.attr.pip_lock),
            requirements_path,
        ], quiet = repo_ctx.attr.quiet)

    elif repo_ctx.attr.requirements:
        requirements_path = repo_ctx.path(repo_ctx.attr.requirements)
    elif repo_ctx.attr.requirements_per_platform:
        requirements_path = _select_requirements_for_platform(repo_ctx)
    else:
        print("Either 'pip_lock', 'requirements' or 'requirements_per_platform' is required")
        fail(
            "Either 'pip_lock', 'requirements' or 'requirements_per_platform' is required",
            attr = "pip_repository",
        )

    r = repo_ctx.execute([
        repo_ctx.attr.python_interpreter,
        "--version"
    ])

    print("STDOUT OF PYTHON --VERSION: " + r.stdout)

    r = repo_ctx.execute([
        repo_ctx.attr.python_interpreter,
        create_repo_exe_path,
        repo_directory,
        requirements_path,
    ] + repo_ctx.attr.wheel_args, quiet = repo_ctx.attr.quiet)
    if r.return_code:
        print("RETURN_CODE: " + r.return_code)
        fail(r.stderr)
    print("PKGS DOWNLOAD STDOUT: " + r.stdout)
    if r.stderr:
        print("PKGS DOWNLOAD STDERR:" + r.stderr)

pip_repository = repository_rule(
    implementation = _pip_repository_impl,
    attrs = {
        "requirements": attr.label(
            allow_files = True,
        ),
        "pip_lock": attr.label(
            allow_files = True,
        ),
        "requirements_per_platform": attr.label_keyed_string_dict(
            allow_files = True,
            allow_empty = False,
        ),
        "python_interpreter": attr.string(default = "python"),
        "wheel_args": attr.string_list(),
        "quiet": attr.bool(default = True),
        "_create_repo_exe": attr.label(
            default = "//tools:create_pip_repository.par",
            executable = True,
            cfg = "host",
        ),
        "_piplock_to_requirements_exe": attr.label(
            default = "//tools:piplock_to_requirements.par",
            executable = True,
            cfg = "host",
        )
    },
)
