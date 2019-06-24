#
# Clean a database either with flyway or by dumping a schema file into it
#
def _flyway_clean_impl(ctx):
    template = ctx.file.config
    schema = ctx.file.schema
    version = ctx.outputs.version
    base = ctx.genfiles_dir.path
    config = ctx.actions.declare_file(base + "/flyway-clean.conf")

    classpath = ""
    add = False
    directory = None
    for file in ctx.files.migrations:
        directory = file.dirname

    for file in ctx.files._classpath:
        if add:
            classpath += ":"
        add = True
        classpath += file.path
    for file in ctx.files.deps:
        classpath += ":" + file.path

    hash_args = ""
    for file in ctx.files.migrations:
        hash_args += " -i " + file.path

    inputs = [template]
    if schema != None:
        inputs.append(schema)
        hash_args += " -i " + schema.path
        create_schema = """java -cp {classpath} io.machinecode.tools.sql.SqlTool \
               -u {url} \
               -U {username} \
               -P {password} \
               -f {schema}""".format(
            classpath = classpath,
            schema = schema.path,
            url = ctx.attr.url,
            username = ctx.attr.username,
            password = ctx.attr.password,
        )
    else:
        create_schema = """java -cp {classpath} io.machinecode.tools.sql.MigrationTool \
              -o clean \
              -c {config}""".format(
            classpath = classpath,
            config = config.path,
        )

    if ctx.file.schema_version != None:
        inputs.append(ctx.file.schema_version)
        hash_args += " -i " + ctx.file.schema_version.path

    command = """/usr/bin/env bash -c "
        cat {template} \
                    | sed 's%SUB_URL%{url}%' \
                    | sed 's%SUB_USER%{username}%' \
                    | sed 's%SUB_PASSWORD%{password}%' \
                    | sed 's%SUB_DIRECTORY%{directory}%' \
                    > {config} && \
        {create_schema} && \
        java -cp {classpath} io.machinecode.tools.sql.HashTool \
             -o {version} \
             {hash_args}
    " """.format(
        create_schema = create_schema,
        version = version.path,
        template = template.path,
        config = config.path,
        classpath = classpath,
        url = ctx.attr.url,
        username = ctx.attr.username,
        password = ctx.attr.password,
        directory = directory,
        hash_args = hash_args,
    )
    ctx.actions.run_shell(
        inputs = inputs + ctx.files.migrations + ctx.files.deps + ctx.files._classpath,
        outputs = [config, version],
        command = command,
    )
    return struct(file = version)

flyway_clean = rule(
    implementation = _flyway_clean_impl,
    output_to_genfiles = True,
    attrs = {
        "_classpath": attr.label_list(default = [
            Label("@org_flywaydb_flyway_core//jar"),
            Label("@gnu_getopt_java_getopt//jar"),
            Label("//src/main/java/io/machinecode/tools/sql"),
        ]),
        "config": attr.label(allow_single_file = True),
        "url": attr.string(),
        "username": attr.string(),
        "password": attr.string(),
        "deps": attr.label_list(),
        "migrations": attr.label_list(),
        "schema": attr.label(allow_single_file = True),
        "schema_version": attr.label(allow_single_file = True),
    },
    outputs = {
        "version": "%{name}.txt",
    },
)

#
# Migrate a database with flyway, optionally cating a schema file in first
#
def _flyway_migrate_impl(ctx):
    template = ctx.file.config
    version = ctx.outputs.version
    base = ctx.genfiles_dir.path
    config = ctx.actions.declare_file(base + "/flyway-migrate.conf")
    migration_version = ctx.actions.declare_file(base + "/flyway_migration_number.txt")
    classpath = ""
    add = False
    directory = None
    log = "-l info" if ctx.attr.debug else ""
    for file in ctx.files.migrations:
        directory = file.dirname

    for file in ctx.files.classpath:
        if add:
            classpath += ":"
        add = True
        classpath += file.path
    for file in ctx.files.deps:
        classpath += ":" + file.path
    command = """/usr/bin/env bash -c "
        cat {template} \
            | sed 's%SUB_URL%{url}%' \
            | sed 's%SUB_USER%{username}%' \
            | sed 's%SUB_PASSWORD%{password}%' \
            | sed 's%SUB_DIRECTORY%{directory}%' \
            > {config} && \
        java -cp {classpath} io.machinecode.tools.sql.MigrationTool \
              -o migrate \
              -c {config} \
              {log} && \
        java -cp {classpath} io.machinecode.tools.sql.SqlTool \
             -u {url} \
             -U {username} \
             -P {password} \
             -c 'select max(version)::text from public.{history_table};' \
            > {migration_version} &&
        java -cp {classpath} io.machinecode.tools.sql.HashTool \
             -o {version} \
             -i {migration_version} \
             -i {schema_version}
    " """.format(
        version = version.path,
        template = template.path,
        config = config.path,
        classpath = classpath,
        url = ctx.attr.url,
        username = ctx.attr.username,
        password = ctx.attr.password,
        directory = directory,
        log = log,
        history_table = ctx.attr.history_table,
        migration_version = migration_version.path,
        schema_version = ctx.file.schema_version.path,
    )
    ctx.actions.run_shell(
        inputs = [template, ctx.file.schema_version] + ctx.files.migrations + ctx.files.deps + ctx.files.classpath,
        outputs = [config, migration_version, version],
        command = command,
    )
    return struct(file = version)

flyway_migrate = rule(
    implementation = _flyway_migrate_impl,
    output_to_genfiles = True,
    attrs = {
        "classpath": attr.label_list(default = [
            Label("@org_flywaydb_flyway_core//jar"),
            Label("@gnu_getopt_java_getopt//jar"),
            Label("//src/main/java/io/machinecode/tools/sql"),
        ]),
        "config": attr.label(allow_single_file = True),
        "url": attr.string(),
        "username": attr.string(),
        "password": attr.string(),
        "debug": attr.bool(),
        "deps": attr.label_list(),
        "migrations": attr.label_list(),
        "history_table": attr.string(default = "flyway_schema_history"),
        "schema_version": attr.label(allow_single_file = True),
    },
    outputs = {
        "version": "%{name}.txt",
    },
)

#
# Run after migrate files
#
def _flyway_after_migrate_impl(ctx):
    base = ctx.genfiles_dir.path

    classpath = ""
    add = False
    for file in ctx.files.classpath:
        if add:
            classpath += ":"
        add = True
        classpath += file.path
    for file in ctx.files.deps:
        classpath += ":" + file.path

    sql_args = ""
    hash_args = ""
    for file in ctx.files.migrations:
        sql_args += " -f " + file.path
        hash_args += " -i " + file.path

    command = """/usr/bin/env bash -c "
        java -cp {classpath} io.machinecode.tools.sql.SqlTool \
             -u {url} \
             -U {username} \
             -P {password} \
             {sql_args} && \
        java -cp {classpath} io.machinecode.tools.sql.HashTool \
             -o {version} \
             -i {schema_version} \
             {hash_args}
    " """.format(
        schema_version = ctx.file.schema_version.path,
        sql_args = sql_args,
        hash_args = hash_args,
        version = ctx.outputs.version.path,
        classpath = classpath,
        url = ctx.attr.url,
        username = ctx.attr.username,
        password = ctx.attr.password,
    )
    ctx.actions.run_shell(
        inputs = [ctx.file.schema_version] + ctx.files.migrations + ctx.files.deps + ctx.files.classpath,
        outputs = [ctx.outputs.version],
        command = command,
    )
    return struct(file = ctx.outputs.version)

flyway_after_migrate = rule(
    implementation = _flyway_after_migrate_impl,
    output_to_genfiles = True,
    attrs = {
        "classpath": attr.label_list(default = [
            Label("@gnu_getopt_java_getopt//jar"),
            Label("//src/main/java/io/machinecode/tools/sql"),
        ]),
        "url": attr.string(),
        "username": attr.string(),
        "password": attr.string(),
        "deps": attr.label_list(),
        "migrations": attr.label_list(),
        "schema_version": attr.label(allow_single_file = True),
    },
    outputs = {
        "version": "%{name}.txt",
    },
)
